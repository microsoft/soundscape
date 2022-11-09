//
//  AppDelegate+Extensions.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import CoreLocation
import RealmSwift

/// A class of static methods used for making the Realm migration code more modular
class RealmMigrationTools {
    
    /// Migrates the Realm databases used by Soundscape to the most recent schema versions. Upon
    /// changing any Realm objects in Soundscape, a migration must be written and the schema version
    /// must be incremented. If there is no actual migration code is needed (e.g. you only deleted a type
    /// but made no other changes) you must still increment to the schema version to acknowledge the change
    ///
    /// - Parameters:
    ///   - databaseConfig: Configuration of the database Realm
    ///   - cacheConfig: Configuration of the cache Realm
    ///   - setCacheAsDefault: If true, the cacheConfig parameter will be set as the default Realm configuration for the app
    class func migrate(database db: Realm.Configuration, cache: Realm.Configuration, setCacheAsDefault: Bool = true) {
        // Create var copies
        var databaseConfig = db
        var cacheConfig = cache
        
        // Migrate the database
        databaseConfig.migrationBlock = {(migration, oldSchemaVersion) in
            // To add a new migration:
            //   1. Go to RealmHelper.swift and increment the schema version of the correct configuration
            //      object. You only need to increment the schema version for Realm databases you have
            //      changed (not necessarily both)
            //   2. Add your migration code to this migration block (see template below). Migrations
            //      should be wrapped in `if oldSchemaVersion < [your new schema version] { ... } `
            //
            // TEMPLATE:
            //
            // if oldSchemaVersion < n {
            //
            //    // MIGRATION NOTES: [Write your migration notes here...]
            //
            // }
        }
        
        // Migrate the cache
        cacheConfig.migrationBlock = {(migration, oldSchemaVersion) in
            // To add a new migration:
            //   1. Go to RealmHelper.swift and increment the schema version of the correct configuration
            //      object. You only need to increment the schema version for Realm databases you have
            //      changed (not necessarily both)
            //   2. Add your migration code to this migration block (see template below). Migrations
            //      should be wrapped in `if oldSchemaVersion < [your new schema version] { ... } `
            //
            // TEMPLATE:
            //
            // if oldSchemaVersion < n {
            //
            //    // MIGRATION NOTES: [Write your migration notes here...]
            //
            // }
        }
        
        // Set the cache as the default configuration
        if setCacheAsDefault {
            Realm.Configuration.defaultConfiguration = cacheConfig
        }
        
        // Run migrations
        let cacheMigratedSuccessfully    = RealmMigrationTools.runSafeMigration(config: cacheConfig)
        let databaseMigratedSuccessfully = RealmMigrationTools.runSafeMigration(config: databaseConfig)
    }
    
    /// Runs a Realm migration by loading the Realm specified by the provided configuration
    /// object. If the schema has not changed, no migration will be run. If the schema has
    /// changed, a migration will be run synchronously. If there are any errors when trying
    /// to load the Realm, the configuration will be altered to completely delete the Realm
    /// and start fresh (nuclear option simply intended to prevent crashes).
    ///
    /// - Parameters:
    ///   - config: Realm configuration object for the Realm that needs to be initialized
    private class func runSafeMigration(config configToMigrate: Realm.Configuration) -> Bool {
        var config = configToMigrate
        let realmName = config.fileURL?.lastPathComponent ?? "unknown file"
        
        do {
            // Assuming the configuration object specifies how to handle migrations,
            // opening the Realm will perform the migration synchronously
            _ = try Realm(configuration: config)
            
            GDLogAppInfo("Realm file migrated if need be (\(realmName))")
            
            return true
        } catch {
            // Log a telemetry event saying that a crash was averted in migrating the specified Realm,
            // but to do so, we had to remove the Realm and start fresh... This means that users may have
            // lost data.
            
            GDATelemetry.track("data_migration_failed", with: ["realm_name": realmName])
            return false
        }
    }
    
}
