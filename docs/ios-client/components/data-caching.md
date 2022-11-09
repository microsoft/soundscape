# Client Data Caching

Data caching in Soundscape is achieved through integration with the Realm database. Realm is similar to CoreData, but is simpler to work with and provides several improvements related to issues like multithreading. This wiki will provide a basic overview of how data is retrieved and cached in Soundscape, and then it dives into how Realm works and how it is integrated into the Soundscape data model.

## Data Retrieval & Caching

### Data Structures

Several data structures have been created to deal with the new structure of POI data coming from the service layer: 

* **GDAVectorTile**: an object that represents the ID of a single vector tile.

This contains a coordinate for the tile (x, y, zoom) and a "quadkey" string which is a base 4 encoding of that coordinate. `GDAVectorTile` also contains a set of static methods for calculating GeoTile related information (e.g. converting between lat/lon and pixel or tile coordinates). This object allows us to determine the specific tile to request from the service layer.

* **GDATileData**: a single geotile of POIs (parsed from a single tile vector tile from the service layer).

This includes the list of all POIs (regular POIs and intersection POIs) in that vector tile and a string quadkey for getting the `GDAVectorTile` object to identify the tile. `GDATileData` extends the `RLMObject` class so that it can be persisted into the Realm database. When a GeoJSON file is retrieved from the services, this class is responsible (in coordination with `GDAGeoJsonFeature` and `GDAGeoJsonGeometry`) for parsing the JSON into `GDASpatialDataResultEntity` objects and `Intersection` objects.

* **GDAGeoJsonFeature**: a helper class responsible for parsing features from downloaded GeoJSON into POIs that can be stored as `GDASpatialDataResultEntity`'s.
* **GDAGeoJsonGeometry**: a helper class responsible for parsing geometry information from downloaded GeoJSON features.
* **GDASpatialDataResultEntity**: the model object which represents a POI.

This extends `RLMObject` so that it can be persisted to the Realm database under a one-to-many relationship with a `GDATileData` object (a single tile owns many POIs).

* **Intersection**: the model object that represents an intersection POI.

This extends `RLMObject` so that it can be persisted into the cache under a one-to-many relationship with a `GDATileData` object (a single tile owns many intersections).

### Tile Data Workflow

The following set of steps describe the process the `GDASpatialDataContext` object follows to get/maintain vector tile data:

 1. When the `SpatialDataContext` object receives updates to the user's geolocation, it looks up the set of tiles which cover the region within 500 meters of the user (between 9 and 16 tiles) and checks to see if the `GDATileData` objects for those tiles are in the cache. For each tile:
     * If a tile is in the cache (and their TTL hasn't expired), `SpatialDataContext` moves on to the next tile.
     * If a tile is not in the cache (or their TTL has expired), the `SpatialDataContext` will retrieve the missing tile data from the server (via `GDAAppServiceModel` class).
         * When making requests for tiles that are in the cache but have expired TTL's, the client includes the tile's ETag. If the request returns a 304 HTTP code, then the tile on the server hasn't changed, so the TTL of the cached tile is simply updated.
         * After receiving the JSON data from the server, the `GDATileData` class will parse the data and `SpatialDataContext` will persist each tile to the cache.
 2. After all required tiles are in the cache (either they were already present, or have been downloaded), `SpatialDataContext` stores the list of current tiles and sends a `GDASpatialDataChangedNotification` notification to let other app components know that there is new spatial data available. (Note that previously, it actually created a `SpatialDataResultsEntity` immediately with this tile data, but we defer that action now and allow SpatialDataResultsEntity's to be created lazily due to threading constraints with Realm).
 3. When any app component needs the current list of POIs, it accesses the list through the `spatialDataResultsEntity` computed property on the `SpatialDataContext` object. This computed property aggregates the POIs from all the current tiles and returns them in a list.

There is a key implication for the app's current `SpatialDataResultsEntity` which falls out from the above process: while we may have much more data cached, the `SpatialDataResultsEntity` will only contain POIs that are within geotiles that are within a 500 meter radius from the user's location.

### TTL and ETags

The caching system does respect a time-to-live value and an ETag for each tile (although TTL's are implemented above the HTTP layer).

* **ETags**: When sending GET requests to the services for tiles that are already in the client's cache, the client includes the ETag that was received for the tile the last time the tile was downloaded. This allows the services to respond either with a new JSON file (HTTP code 200) if the file has changed, or return a 304 HTTP code, indicating the file hasn't changed since it was last downloaded.
* **TTLs**: When pulling tiles from the local cache, the client app check the time at which the client last pulled the tile. If this time was over *one week* in the past, then the tile is expired and the client attempts to update the tile from the services.

## The Realm Database

Realm is a mobile platform database designed to be fast and efficient. Realm is integrated into iOS applications by creating model classes that extend the base class RLMObject. All properties on RLMObject subclasses can be persisted into the database (so long as the property types are either subclasses of RLMObject or are one of several supported primitive types). Properties can be explicitly excluded from being stored in the database by providing Realm with the name of the property to ignore. After data has been added to an object of an RLMObject subclass, that object can be persisted to the database by getting a reference to the database, creating a transaction, and saving or updating the object in the database.

### Retrieving Data

Data is retrieved from the Realm database directly through the class that models the data you want to retrieve. For instance, if you wanted to find the vector tile data for the tile (x: 10472, y:22982, zoom: 16), you would do the following:

```objc
// Get the quadkey for the tile
GDAVectorTile * tile = [[GDAVectorTile alloc] initWithTileX: 10472 tileY: 22982 zoom:16];
    
// Retrieve the tile data from the cache
RLMResults<GDATileData *> * results = [GDATileData objectsWhere:@"quadkey = %@", tile.quadKey];
```

Queries to the Realm database using `objectsWhere:` use a SQL-like syntax in which you specify the name of the property to search for and the value that it should equal. Queries using `objectsWhere:` return a list of results in an `RLMResults<>` object. In many cases, you probably know there is only one object that should be returned from your search. In that case, you can do something slightly different to directly access that single result:

```objc
GDATileData * cachedTile = [GDATileData objectsWhere:@"quadkey = %@", tile.quadKey].firstObject;
    
// Check to make sure the object was actually found (if not, either your query is wrong, or the object isn't in the cache
if (cachedTile != nil) {
    // Do something with the tile data you just retrieved...
}
```

### Persisting Data

Persisting data to the Realm database is very simple. It simply involves creating a model object (any class which derives from `RLMObject`), setting it's property values, and writing it to the database in a transaction. Here is an example of how to persist changes to a newly allocated object `GDASpatialDataResultEntity`.

 1. Create a new `GDASpatialDataResultEntity`:

    ```objc
    GDASpatialDataResultEntity * entity = [[GDASpatialDataResultEntity alloc] initWithJSON:json];
    ```

 2. Store the object:

    ```objc
    @autoreleasepool {
        RLMRealm * realm  = [RLMRealm defaultRealm];
                     
        // Add to Realm with transaction
        [realm beginWriteTransaction];
        [realm addOrUpdateObject:entity];
        [realm commitWriteTransaction];
    }
    ```

Or for an object already in the cache:

 1. Get the object:

    ```objc
    GDASpatialDataResultEntity * entity = [GDASpatialDataResultEntity objectsWhere:@"entityId = %@", entityId].firstObject;
    ```

 2. Using an `@autoreleasepool {...}` block, update the object in a transaction (you *must* use transactions):

    ```objc
    if (entity != nil) {
        // Update the entity's priority from 0 to 1
        @autoreleasepool {
            RLMRealm * realm  = [RLMRealm defaultRealm];
                     
            // Add to Realm with transaction
            [realm beginWriteTransaction];
            entity.priority = 1;
            [realm commitWriteTransaction];
        }
    }
    ```

### Important Catches

There are several catches that can cause you issues when working with Realm. This list should help prevent you from falling into the same issues we hit when first implementing caching in Soundscape:

 1. **RLMObject subclass properties must be accessed via property accessors, not ivar references:** One interesting thing you will notice when debugging objects which derive from RLMObject is that after pulling the object from the database, Xcode shows that all property values are nil, but if you print the object to the debugging console, the object appears to have valid property values. This is because Realm does not use the property ivars created by the objective c compiler except when you are initially creating an object to add to the database. When you access a property of an object retrieved from the database, Realm augments the property accessor to reach directly into the database to get the data rather than storing the database value on the object. This means that if you implement computed properties or methods on a model class that derives from RLMObject, you must use `self.property` syntax to access property values rather than `_property` ivar syntax.
 2. **RLMObject subclass objects should only be used on the thread they were created on:** RLMObject's are not thread safe. If you attempt to access an RLMObject form a thread other than the one it was created on, the app will crash at runtime. For this reason, you should always pull data from the cache from the thread you need it in. The updated implementation of SpatialDataContext respects this by not storing the current `SpatialDataResultsContext`, but constructing it from the cache anytime the `SpatialDataContext.spatialDataResultsEntity` property is accessed. 
 3. **Wrap usage of `RLMRealm * realm  = [RLMRealm defaultRealm];` in `@autoreleasepool{...}`:** Realm keeps the cached data in memory until all RLMRealm objects have been disposed. This can be bad if we are trying to delete the cache but references to an RLMRealm object is still in memory. This can be fixed by using an autorelease pool to ensure that the RLMRealm object gets disposed as soon as you are done using it.
 4. **Making changes to a model object? Delete the app before running, or write a migration script:** If you change a model object in a way that requires the object to be represented different in the database, Realm needs a way to update the currently stored information to work with the new class definition. If the changes you are making are against a version of the app that doesn't have any real users yet (only you have access to the original model version) then you can simply delete the app off your device and run the app from Xcode to get a fresh install. If the version of the model you are changing is already distributed to real users, then you have to provide Realm with a migration script that describes how to update the database already on the user's devices to match the new model class definition. You can read about writing migration scripts in the [Realm documentation](https://realm.io/docs/objc/latest/#migrations).
