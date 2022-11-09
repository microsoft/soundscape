# Data Plane?

In a networking context - the control plane is normally where decisions, routing, command invocation, etc take place.  The data plane is the engine that actually more focused on shipping bits to the various parties.

In the Soundscape context:

* the application and any command-like services are the control plane.
* the data service that provides basic map tiles is the data plane.  In the best case the generation of this data is client independent and done in advance.  Further the service may be fronted by a CDN or other file transfer/caching service designed to maximize our ability to support many clients cheaply.

## Tiles

Tiles are a way to deliver pre-bounding boxed content to a requestor and are a common in the mapping space.  The tiles may represent pre-rendered content, content rendered on the fly or consist of the data bounded by that tile.

## Addressing

A tile has an x,y coordinate and a zoom level.  These three parameters can be translated by standard formula and projection into a bounding box lat lng and vice versa.  Conventions for addressing, how big a tile is at each zoom level, and sample code for translating from lat/lng to tile address and vice versa can be found here:
[Slippy tile names](http://wiki.openstreetmap.org/wiki/Slippy_map_tilenames)

The current URL for Soundscape tiles is constructed as:

`base_url/zoom/x/y.json`

where zoom is currently always 16, x is the x address of the tile, and y is the y address of the tile.  Tile X/Y are computed using the zoom and the latitude/longitude as described here: [Slippy tile names](http://wiki.openstreetmap.org/wiki/Slippy_map_tilenames).

## Standards

The data plane service uses GeoJSON as the format for individual tiles.  The GeoJSON specification can be found here <https://tools.ietf.org/html/rfc7946>

GeoJSON is primarily a specification for how geometric features can be described in JSON.  The specification allows for extensions/other data in specific locations but defines the format of geometric data.

In essence the JSON is defined to look like this:

```json
{
  "type": "FeatureCollection",
  "features": [{
      "type": "Feature",
      "geometry": {
        "type": "Point",
        "coordinates": [102.0, 0.5]
      },
      "properties": {
        
      }
    }, {
      "type": "Feature",
      "geometry": {
        "type": "LineString",
        "coordinates": [
          [102.0, 0.0],
          [103.0, 1.0],
          [104.0, 0.0],
          [105.0, 1.0]
        ]
      },
      "properties": {
        
      }
    }]
}
```

The properties value may contain arbitrarily nested information.  Further additional information can appear in the Features object as long as it doesn't interfere with the standard keys eg. 'geometry'. Actual geometry type information can include:

* Point
* Multipoint (point collection)
* LineString (point collection)
* Polygon, Multipolygon - array of LineString or Points
* MultiPolygon - array of Polygons

Each position is a lat/lng.  Sometimes a 3rd parameter is present indicating elevation.

## Soundscape use of GeoJSON

Soundscape currently uses a single format for its geojson features that is common across points of interest, roads, intersections, etc.

Each feature has the following additional properties beyond the GeoJSON specification:

* `osm_ids`: array of OSM ids cooked to avoid the fact that OSM ids are not unique across nodes, ways, relations, and areas.  For a feature that directly represents an OSM element, this will be an array of a single OSM id. (**TODO:** document standard cooking scheme)
* `feature_type`: indicates the primary OSM tag used to select this feature from the wider OSM dataset eg. 'highway'
* `feature_value`: the value of the primary OSM tag used to select this feature eg. 'residential'
* `properties`: contains the OSM tags associated with the underlying OSM object.  These are minimally filtered to remove some sourcing and project management information.

### Geometry, Bounding boxes

All tile generation is being done via bounding box intersections.  This can produce false positives e.g. a tile might intersect with the bbox of a feature but not the feature itself.  All coordinates reflect the 4326/WGS-84 projection (<http://spatialreference.org/ref/epsg/wgs-84/>)

### Synthesized Features

The following features are synthesized and are not present in the OSM dataset:

* `intersections`: OSM defines an intersection as a shared node between ways rather than ways that may cross eg. a bridge over a highway.
* `entrance lists`: OSM defines entrances to be a node on a building.  These synthesized objects capture all of the entrances described on a given building.

#### Intersections Detail

* `feature_type`: 'highway'
* `feature_value`: 'gd_intersection'
* `osm_ids`: array of the ways that intersect at this point as described by their OSM id.
* `geometry`: intersection point
* `properties`: empty.  Properties of the intersecting roads should be retrieved using the osm ids of the individual ways.

#### Entrance Detail

* `feature_type`: 'gd_entrance_list'
* `feature_value`: ''
* `osm_ids`: array consisting of:
  * osm_id of the building
  * osm_id(s) of the entrances on the building
* `geometry`: MultiPoint containing the entrance points.
* `properties`: empty. Properties of the entrances should be retrieved using the osm ids of the individual ways.

### feature_type

Currently we extract data marked with the following tags which will produce features:

* `amenity`
* `building`
* `entrance`
* `highway`
* `historic`
* `landuse` (limited to construction sites)
* `leisure`
* `office`
* `shop`
* `tourism`

In general we're outputting features with all the OSM elements that contain these tags except for:

* `highway='track'`

### Order of Data

The order of any GeoJSON defined subsections of the GeoJSON are ordered as required in the GeoJSON specification.  The recommendation to use right hand rule winding order is not followed.

The order of features within the FeatureCollection, and the order of tags within the collections of name/value pairs is not defined.
