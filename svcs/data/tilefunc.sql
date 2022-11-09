-- Copyright (c) Microsoft Corporation.
-- Licensed under the MIT License.

CREATE OR REPLACE FUNCTION
   soundscape_tile (zoom int, tile_x int, tile_y int)
   RETURNS TABLE(type text, osm_ids bigint[], feature_type varchar, feature_value varchar, geometry jsonb, properties jsonb)
   AS $$
   SELECT 'Feature' as type, osm_ids, feature_type, feature_value, ST_AsGeoJson(geometry, 6)::jsonb as geometry, hstore_to_jsonb(properties) as properties
             FROM (
               WITH roads as (
                 SELECT osm_id as osm_id, feature_type, feature_value, geometry, properties from osm_roads where geometry && TileBBox(zoom, tile_x, tile_y, 4326) and service != 'parking_aisle' order by osm_id
               ), places as (
                 SELECT osm_id, feature_type, feature_value, geometry, properties from osm_places where geometry && TileBBox(zoom, tile_x, tile_y, 4326) and not (properties ? 'boundary' and properties ? 'historic')
               ), entrances as (
                 SELECT osm_id, feature_value, properties, geometry from osm_entrances where geometry && TileBBox(zoom, tile_x, tile_y, 4326)
               )
               SELECT ARRAY[osm_id] as osm_ids, feature_type, feature_value, geometry, properties from places
               UNION
               SELECT ARRAY[osm_id] as osm_ids, feature_type, feature_value, geometry, properties from roads
               UNION
               SELECT DISTINCT array_agg(osm_id) as osm_ids, 'highway' as feature_type, 'gd_intersection' as feature_value, point AS geometry, hstore('') as properties
                 FROM ( SELECT osm_id, (ST_DumpPoints(geometry)).geom as point
                        FROM roads
                 ) as ps
                 WHERE ST_Within(point, TileBBox(zoom, tile_x, tile_y, 4326))
               GROUP BY point HAVING COUNT(osm_id) > 1
               UNION
               SELECT building.osm_id || array_agg(e.osm_id) as osm_ids, 'gd_entrance_list' as feature_type, 'yes' as feature_value, ST_Collect(e.geometry) as geometry, hstore('') as properties
                 FROM (
                   SELECT properties, osm_id, (ST_DumpPoints(geometry)).geom as building_point from places where feature_type='building'
                 ) as building, entrances e
               WHERE building.building_point = e.geometry group by building.osm_id
            ) as elements
            ORDER BY osm_ids
$$
    LANGUAGE SQL
    STABLE;
