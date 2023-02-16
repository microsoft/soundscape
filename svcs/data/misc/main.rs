// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

use std::fs;
use std::io::{BufRead, BufReader};
use std::path::{Path, PathBuf};
use std::process::{Command, ExitStatus, Stdio};
use std::thread;
use std::time::Duration;

use anyhow::{anyhow, Context, Result};
use clap::Parser;
use env_logger::Env;
use itertools::Itertools;
use log::{error, info, trace};
use openssl::ssl::{SslConnector, SslMethod};
use postgres::Client;
use postgres_openssl::MakeTlsConnector;

//
// OSM ingester for Microsoft Soundscape
//
// This design favors the delay/try again strategy over failure based
// on our experiences with transient failures with OSM, Postgres, and Azure.
// failure will cause a restart by Kubernetes
//

const SCHEMA_IMPORT: &str = "import";
const SCHEMA_PUBLIC: &str = "public";
const SCHEMA_BACKUP: &str = "backup";

const DELAY_DB_ERROR: Duration = Duration::from_secs(5 * 60);
const DELAY_NETWORK_ERROR: Duration = Duration::from_secs(60 * 60);
const DELAY_NO_WORK: Duration = Duration::from_secs(8 * 60 * 60);
const DELAY_UNKNOWN_ERROR: Duration = Duration::from_secs(60 * 60);

const OSM_TABLES: &[&str; 3] = &["osm_roads", "osm_places", "osm_entrances"];

#[derive(Debug, Parser)]
#[clap(name = "osmingester")]
#[clap(about = "OSM Ingester for Soundscape", long_about = None)]
struct Args {
    /// Path to file containing URL from which to retrieve PBF
    #[clap(long, value_parser)]
    pbf: PathBuf,
    /// Path to file containing Postgres connection string
    #[clap(long, value_parser)]
    dsn: PathBuf,
    /// Path to OSM2PGSQL executable
    #[clap(long, value_parser, default_value = "osm2pgsql")]
    osm2pgsql: PathBuf,
    /// Path to file containing SQL to configure Postgres
    #[clap(long, value_parser)]
    provision_sql: Vec<PathBuf>,
    /// Ignore cert verification
    #[clap(long)]
    insecure: bool,
    #[clap(long, value_parser)]
    /// Path to working directory
    work: PathBuf,
    /// Launch osm2pgsql under a debugger
    #[clap(long)]
    debug: bool,
    /// Optimize for memory footprint
    #[clap(long)]
    optimize: bool,
    /// Path to OSM2PGSQL 'flex' style mapping file
    #[clap(long, value_parser)]
    mapper: PathBuf,
}

fn postgres_connect(dsn: &str, insecure: bool) -> Result<Client> {
    let mut builder = SslConnector::builder(SslMethod::tls())?;
    if insecure {
	builder.set_verify(openssl::ssl::SslVerifyMode::NONE);
    }
    let connector = MakeTlsConnector::new(builder.build());
    postgres::Client::connect(dsn, connector).context("connecting database")
}

fn provision_db(dsn: &str, insecure: bool, pgcmds: &[PathBuf]) -> Result<()> {
    let mut client = postgres_connect(dsn, insecure)?;
    for pgcmd in pgcmds.iter() {
        let cmds = fs::read_to_string(pgcmd).expect("provision sql");
        client
            .batch_execute(&cmds)
            .with_context(|| format!("failed to execute from {}", pgcmd.display()))?;
    }
    Ok(())
}

fn fetch_url_to_file(url: &str, path: &Path) -> Result<()> {
    let mut f = fs::File::create(path)?;
    let mut response = reqwest::blocking::get(url)?;
    response.copy_to(&mut f)?;
    Ok(())
}

fn table_exists(client: &mut Client, schema: &str, table: &str) -> Result<bool> {
    let query = "SELECT EXISTS(SELECT * FROM information_schema.tables WHERE table_name=$1 AND table_schema=$2)";
    let row = client.query_one(query, &[&table, &schema])?;
    let found: bool = row.try_get("exists")?;
    Ok(found)
}

fn rotate_schema(dsn: &str, insecure: bool) -> Result<()> {
    let mut client = postgres_connect(dsn, insecure)?;

    // N.B. Unable to to prepare these statements
    let alter_schema = |current: &str, new: &str, table: &str| -> String {
        format!("ALTER TABLE {}.{} SET SCHEMA {}", current, table, new)
    };
    let drop_table =
        |schema: &str, table: &str| -> String { format!("DROP TABLE {}.{}", schema, table) };

    for t in OSM_TABLES.iter() {
        let mut cmds = Vec::<String>::new();
        let mut dropping_backup = false;

        let (import_present, backup_present, public_present) =
            [SCHEMA_IMPORT, SCHEMA_BACKUP, SCHEMA_PUBLIC]
                .iter()
                .map(|s| table_exists(&mut client, s, t).unwrap_or(false))
                .collect_tuple()
                .expect("collect_tuple");

        // XXX is this a more serious error
        if !import_present {
            error!("ROTATE: no import table for {} to rotate", t);
            continue;
        }

        // Drop the backup if we have a live table
        if public_present && backup_present {
            cmds.push(drop_table(SCHEMA_BACKUP, t));
            dropping_backup = true;
        }

        if public_present {
            cmds.push(alter_schema(SCHEMA_PUBLIC, SCHEMA_BACKUP, t));
        }
        cmds.push(alter_schema(SCHEMA_IMPORT, SCHEMA_PUBLIC, t));
        cmds.push("".to_string());
        let batch = cmds.join(";\n");

        match client.simple_query(&batch) {
            Ok(_) => {
                info!("ROTATE: Rotated '{}'", t);
                if dropping_backup {
                    trace!("ROTATE: Dropped backup of '{}'", t);
                }
            }
            Err(why) => {
                // N.B. Allow the tables to tear between PBF versions
                //      Other option is a single larger transaction
                error!("ROTATE: Rotation of {} failed: {}", t, why);
            }
        }
    }
    Ok(())
}

fn cmd_log_stderr(cmd: &mut Command) -> Result<ExitStatus> {
    let mut child = cmd.stderr(Stdio::piped()).spawn()?;

    {
        let stderr = child.stderr.take().expect("stderr");
        let reader = BufReader::new(stderr);

        for l in reader.lines().map(|l| l.unwrap()) {
            info!("OSM2PGSQL: {}", l);
        }
    }
    Ok(child.wait()?)
}

fn ingest_pbf(osm2pgsql: &Path, debug: bool, optimize: bool, mapper: &Path, dsn: &str, pbf: &Path) -> Result<()> {
    info!("INGEST: Ingest to 'import' schema");
    let flat_path = pbf.with_file_name("active.flat");
    let mut cmd =
	if debug {
	    Command::new("gdb")
	} else {
 	    Command::new(osm2pgsql)
	};

    if debug {
	cmd.args(["-ex=r", "--batch", "--args"])
	    .arg(osm2pgsql);
    }

    cmd
        .arg("--output=flex")
        .arg("--style")
        .arg(mapper.as_os_str())
        .args(["--database", dsn]);

    if optimize {
	cmd
	    .arg("--flat-nodes")
	    .arg(flat_path.as_os_str())
	    .arg("--slim")
	    .arg("--drop");
    }

   cmd
        .arg(pbf.as_os_str());

    let status = cmd_log_stderr(&mut cmd);

    match status {
        Ok(code) if code.success() => {
            info!("INGEST: PBF imported");
            Ok(())
        }
        Ok(code) => {
            error!("INGEST: Failure: code {}, possible transient", code);
            Err(anyhow!("Ingestion failed"))
        }
        Err(_) => {
            error!("INGEST: Failure, no code");
            Err(anyhow!("Ingestion failed"))
        }
    }
}

enum DataStatus {
    NothingToIndex,
    NeedsIndexing,
}

fn refresh_pbf(url_pbf: &str, force: bool, work: &Path, active_pbf: &Path) -> Result<DataStatus> {
    let workbuf = PathBuf::from(work);
    let url_md5 = url_pbf.to_string() + ".md5";
    let new_md5 = workbuf.join("new.md5");
    let new_pbf = workbuf.join("new.pbf");
    let active_md5 = workbuf.join("active.md5");

    // Compare new MD5 or old one if present
    let active_md5_data = if force {
        String::new()
    } else {
        fs::read_to_string(&active_md5).unwrap_or_default()
    };
    fetch_url_to_file(&url_md5, &new_md5)?;
    let new_md5_data = fs::read_to_string(&new_md5)?;
    if active_md5_data.eq(&new_md5_data) {
        return Ok(DataStatus::NothingToIndex);
    }

    // Activate new PBF
    info!("REFRESH: Downloading {}", url_pbf);
    fetch_url_to_file(url_pbf, &new_pbf)?;
    info!("REFRESH: Downloaded {}", url_pbf);
    fs::rename(new_pbf, active_pbf)?;
    fs::rename(new_md5, &active_md5)?;
    Ok(DataStatus::NeedsIndexing)
}

fn ingester(args: Args) -> Result<()> {
    let work = &args.work;
    let pbf = PathBuf::from(work).join("active.pbf");
    let mut force_refresh = true;

    loop {
        info!("RELOAD: Parameters");
        let pbf_url = fs::read_to_string(&args.pbf).expect("pbf url");
        let dsn = fs::read_to_string(&args.dsn).expect("dsn");

        if provision_db(&dsn, args.insecure, &args.provision_sql).is_err() {
            error!("PROVISION: Failed, delaying for db transient");
            thread::sleep(DELAY_DB_ERROR);
            continue;
        }
        info!("PROVISION: Successful");

        let delay = match refresh_pbf(&pbf_url, force_refresh, work, &pbf) {
            Err(_) => {
                error!("FAIL: failed to refresh PBF, sleeping");
                DELAY_NETWORK_ERROR
            }
            Ok(DataStatus::NothingToIndex) => {
                info!("INGESTER: nothing to do, sleeping...");
                DELAY_NO_WORK
            }
            Ok(DataStatus::NeedsIndexing) => {
                force_refresh = false;
                info!("INGESTER: new PBF to index, indexing...");
                if ingest_pbf(&args.osm2pgsql, args.debug, args.optimize, &args.mapper, &dsn, &pbf).is_err() {
                    error!("INGESTER: index failed, sleeping...");
                    DELAY_UNKNOWN_ERROR
                } else if rotate_schema(&dsn, args.insecure).is_err() {
                    error!("INGESTER: Rotation failed, sleeping");
                    DELAY_UNKNOWN_ERROR
                } else {
                    info!("INGESTER: New PBF is active, sleeping");
                    DELAY_NO_WORK
                }
            }
        };
        thread::sleep(delay);
    }
}

fn main() -> Result<()> {
    env_logger::Builder::from_env(Env::default().default_filter_or("info")).init();
    let args = Args::parse();
    ingester(args)?;
    Ok(())
}
