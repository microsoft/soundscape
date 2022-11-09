# OSM Indexing

These services used IMPOSM (https://github.com/omniscale/imposm3) to
import OSM planet data into PostGIS.  We use IMPOSM's mapping facility
to do light filtering on the OSM data and inject it into the database.

Recently questions have been asked about the maintenance level of
IMPOSM.  We have explored other alternatives.  In our prototyping, it
was possible to configure OSM2PGSQL to produce very similar data as
IMPOSM with the '--output=flex' and an appropriate LUA style.
