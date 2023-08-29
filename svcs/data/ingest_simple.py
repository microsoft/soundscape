import argparse
import logging
import json
import psycopg2
from psycopg2.extensions import make_dsn, parse_dsn
from psycopg2 import connect, OperationalError
import os
from datetime import datetime
import subprocess
import asyncio
import aiopg
import urllib.parse

parser = argparse.ArgumentParser(description='Ingestion engine for Soundscape')
# Arguments needed for Imposm
parser.add_argument('--imposm', type=str, help='Imposm executable path', default='imposm')
parser.add_argument('--mapping', type=str, help='Mapping file path use by Imposm', default='mapping.yml')
parser.add_argument('--where', metavar='regions', nargs='+', type=str, help='Region names for extracts that match the name key in extracts.json, for example, great-britain')
parser.add_argument('--extracts', type=str, default='extracts.json', help='Extracts file which defines urls for extracts')
parser.add_argument('--config', type=str, help='Config file for fetching diffs.', default='config.json')
parser.add_argument('--cachedir', type=str, help='Imposm temp directory where coords, nodes, relations and ways are stored', default='/tmp/imposm3_cache')
parser.add_argument('--diffdir', type=str, help='Imposm diff directory location', default='/tmp/imposm3_diffdir')
parser.add_argument('--pbfdir', type=str, help='Where the extracts are stored in .pbf format', default='.')
parser.add_argument('--expiredir', type=str, help='Expired tiles directory', default='/tmp/imposm3_expiredir')

# Logging
parser.add_argument('--verbose', action='store_true', help='Turn on verbose logging.')

def make_osm_dsn(args):
    dsn = make_dsn(
                    user=os.environ['POSTGIS_USER'],
                    password=os.environ['POSTGIS_PASSWORD'],
                    host=os.environ['POSTGIS_HOST'],
                    port=os.environ['POSTGIS_PORT'],
                    dbname=os.environ['POSTGIS_DBNAME'],
                )
    return dsn

def get_url_dsn(dsn):
        args = parse_dsn(dsn)
        user = args.get('user', '')
        password = args.get('password', '')
        host = args.get('host', '')
        port = args.get('port', '')
        dbname = args.get('dbname', '')
        return f"postgis://{user}:{password}@{host}:{port}/{dbname}"

def check_table(cursor, name, schema):
        """Check for tables in the DB table exists in the DB"""
        sql = """ SELECT EXISTS (SELECT 1 AS result from information_schema.tables 
                 where table_name like  TEMP_TABLE and table_schema = 'TEMP_SCHEMA'); """
        cursor.execute(sql.replace('TEMP_TABLE', '%s' % name).replace('TEMP_SCHEMA', '%s' % schema))
        
        return cursor.fetchone()[0]

def fetch_extracts(config, extracts):
    logger.info('Fetch extracts: START')
    fetched = False
    for e in extracts:
        fetched_extract = fetch_extract(config, e['url'])
        fetched = fetched or fetched_extract
    logger.info('Fetch extracts: DONE')
    return fetched

def fetch_extract(config, url):
    # a local PBF may already be present
    logger.info('Fetching {0}'.format(url))
    # wget won't overwrite data unless it's in timestamp mode
    local_pbf = os.path.join(config.pbfdir, os.path.basename(url))

    try:
        before_token = os.path.getmtime(local_pbf)
    except OSError:
        before_token = None

    try:
        subprocess.run(['wget', '-N', url, '--directory-prefix', config.pbfdir], check=True)
        after_token = os.path.getmtime(local_pbf)
    except Exception:
        raise

    logger.info('Fetching {0}: DONE'.format(url))
    if before_token == after_token:
        return False
    else:
        return True

def first_pbf_import(config):
    pbf_download_complete = fetch_extracts(config, osm_extracts)
    return pbf_download_complete

def connect_to_postgresdb(dsn):
    try:
        # TODO: Need to change this so the db name isn't hardcoded
        # Need to enumerate db s. Will probably have to use psql
        dsn_init = dsn.replace('dbname=osm', 'dbname=postgres')
        connection = connect(dsn_init)
        cursor = connection.cursor()
        cursor.close()
        connection.close()

    except OperationalError as e:
        logger.warning('Unable to connect to "{0}: {1}": FAILED'.format("postgres", e))

async def provision_database_async(postgres_dsn, osm_dsn):
    async with aiopg.connect(dsn=postgres_dsn) as conn:
        cursor = await conn.cursor()
        try:
            await cursor.execute('CREATE DATABASE osm')
        except psycopg2.ProgrammingError:
            logger.warning('Database already existed at "{0}"'.format(postgres_dsn))
    async with aiopg.connect(dsn=osm_dsn) as conn:
        cursor = await conn.cursor()
        await cursor.execute('CREATE EXTENSION IF NOT EXISTS postgis')
        await cursor.execute('CREATE EXTENSION IF NOT EXISTS hstore')

def provision_database(postgres_dsn, osm_dsn):
    loop = asyncio.get_event_loop()
    loop.run_until_complete(provision_database_async(postgres_dsn, osm_dsn))

def provision_database_soundscape(osm_dsn):
    loop = asyncio.get_event_loop()
    loop.run_until_complete(provision_database_soundscape_async(osm_dsn))

async def provision_database_soundscape_async(osm_dsn):
    ingest_path = os.environ['INGEST']
    async with aiopg.connect(dsn=osm_dsn) as conn:
        cursor = await conn.cursor()
        with open(ingest_path + '/' + 'postgis-vt-util.sql', 'r') as sql:
            await cursor.execute(sql.read())
        with open(ingest_path + '/' + 'tilefunc.sql', 'r') as sql:
            await cursor.execute(sql.read())

def import_write(config, incremental):
    logger.info('writing of OSM tables: START')
    dsn = make_osm_dsn(config)
    dsn_url = get_url_dsn(dsn)
    imposm_args = [config.imposm, 'import', '-mapping', config.mapping, '-write', '-connection', dsn_url, '-srid', '4326', '-cachedir', config.cachedir]
    if incremental:
        imposm_args.extend(['-diff', '-diffdir', config.diffdir])
    subprocess.run(imposm_args, check=True)
    logger.info('Write of OSM tables: DONE')

def import_rotate(config, incremental):
    logger.info('Table rotation: START')
    dsn = make_osm_dsn(config)
    dsn_url = get_url_dsn(dsn)
    imposm_args = [config.imposm, 'import', '-mapping', config.mapping, '-connection', dsn_url, '-srid', '4326', '-deployproduction', '-cachedir', config.cachedir]
    if incremental:
        imposm_args.extend(['-diff', '-diffdir', config.diffdir])
    subprocess.run(imposm_args, check=True)
    logger.info('Table rotation: DONE')

def run_diffs(config):
    # config.json controls where the diffs are downloaded from and how often it runs (1h)
    dsn = make_osm_dsn(config)
    dsn_url = get_url_dsn(dsn)    
    logger.info('Incremental update - STARTED')
    subprocess.run([config.imposm, 'run', '-config', config.config, '-mapping', config.mapping, '-connection', dsn_url, '-srid', '4326', '-cachedir', config.cachedir, '-diffdir', config.diffdir, '-expiretiles-dir', config.expiredir, '-expiretiles-zoom', '16'], check=True)
    logger.info('Incremental update - DONE')

def connect_to_osmdb(dsn, config):
    try:
        # TODO: Change the strings to variables that we can pass in as args
        dsn_init = dsn.replace('dbname=osm', 'dbname=postgres')
        logger.info('Attempting to provision "{0}: ": PROVISIONING'.format(os.environ['POSTGIS_DBNAME']))
        provision_database(dsn_init, dsn)

        download_complete = first_pbf_import(config)

        if download_complete:
            # Let Imposm do its stuff: read, import, write to db, rotate tables
            import_extracts(config, osm_extracts, True)
            import_write(config, True)
            import_rotate(config, True)
            # This deploys the .sql files onto the soundscape database
            provision_database_soundscape(dsn)
            # Once we've run everything we want to setup diffs              
            # We want to get the diff file(s) and run Imposm (it writes the diffs to the production table). This is managed by the settings in config.json           
            run_diffs(config)            
    
    except OperationalError as e:
        logger.warning('Unable to connect to "{0}: {1}": FAILED'.format(os.environ['POSTGIS_DBNAME'], e))  

def import_extracts(config, extracts, incremental):
    imported = {}
    for e, i in zip(extracts, range(len(extracts))):
        if i == 0:
            cache = '-overwritecache'
        else:
            cache = '-appendcache'
        urlbits = urllib.parse.urlsplit(e['url'])
        pbf = os.path.basename(urlbits.path)
        if pbf in imported:
            continue
        imported[pbf] = True
        import_extract(config, pbf, cache, incremental)

def import_extract(config, pbf, cache, incremental):
    logger.info('Import of {0} : START'.format(pbf))
    imposm_args = [config.imposm, 'import', '-mapping', config.mapping, '-read', config.pbfdir + "/" + pbf, '-srid', '4326', cache, '-cachedir', config.cachedir]
    if incremental:
        imposm_args.extend(['-diff', '-diffdir', config.diffdir])
    subprocess.run(imposm_args, check=True)
    logger.info('import of {0}: DONE'.format(pbf))    

def import_osm_data(config):
    # check whether there is an existing OSM db and schema
    try:
        dsn = make_osm_dsn(config)
        # Can we connect to the postgres db?
        connect_to_postgresdb(dsn)
        # Can we connect to the osm db?
        connect_to_osmdb(dsn, config)

    except OperationalError as e:
        logger.warning('Unable to connect to "{0}: {1}": FAILED'.format(config.postgis_dbname, e))

if __name__ == '__main__':
    args = parser.parse_args()

    if args.verbose:
        loglevel = logging.INFO
    else:
        loglevel = logging.WARNING

    if args.where:
        extracts_f = open(args.extracts, 'r')
        # The below is just for debug. Comment out above if you want to debug locally and not in container
        # extracts_f = open("Soundscape/svcs/data/extracts.json", 'r')
        osm_extracts = json.load(extracts_f)

    # pulls the regions/countries/whatever extracts that are provided by GeoFabrik we are interested in from extracts.json
    if args.where:
        osm_extracts = list(filter(lambda e: e['name'] in args.where, osm_extracts))        

    logging.basicConfig(level=loglevel, format='%(asctime)s:%(levelname)s:%(message)s')
    logger = logging.getLogger()

    try:
        import_osm_data(args)

    finally:
        print('Terminating logging')
        logging.shutdown()