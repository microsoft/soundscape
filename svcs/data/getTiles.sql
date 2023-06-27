-- from https://gis.stackexchange.com/a/428472

-- Source: https://wiki.openstreetmap.org/wiki/Slippy_map_tilenames#PostgreSQL
CREATE OR REPLACE FUNCTION lon2tile(lon DOUBLE PRECISION, zoom INTEGER)
  RETURNS INTEGER AS
$BODY$
    SELECT FLOOR( (lon + 180) / 360 * (1 << zoom) )::INTEGER;
$BODY$
  LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE FUNCTION lat2tile(lat double precision, zoom integer)
  RETURNS integer AS
$BODY$
    SELECT floor( (1.0 - ln(tan(radians(lat)) + 1.0 / cos(radians(lat))) / pi()) / 2.0 * (1 << zoom) )::integer;
$BODY$
  LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE FUNCTION getTiles(extent box2d, min_zoom integer, max_zoom integer)
  RETURNS TABLE (x integer, y integer, z integer) AS
$BODY$
    SELECT x, y, z
    FROM
        (
            SELECT
                lon2tile(ST_XMin(extent), zoom) AS x_min,
                lon2tile(ST_XMax(extent), zoom) AS x_max,
                lat2tile(ST_YMax(extent), zoom) AS y_min,
                lat2tile(ST_YMin(extent), zoom) AS y_max,
                zoom AS z
            FROM
                generate_series(min_zoom, max_zoom) zoom
            GROUP BY zoom
        ) minmax_per_zoom
        CROSS JOIN
        generate_series(x_min, x_max) x
        CROSS JOIN
        generate_series (y_min, y_max) y
$BODY$
  LANGUAGE SQL
;

CREATE OR REPLACE FUNCTION getAll16Tiles()
  RETURNS TABLE (x integer, y integer, z integer) AS
$BODY$
    SELECT x, y, z
    FROM
    getTiles(
        (SELECT ST_Extent(ST_Transform(geometry, 4326))
        FROM osm_places), 16, 16);
$BODY$
  LANGUAGE SQL
;
