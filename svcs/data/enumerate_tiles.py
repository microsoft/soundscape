#!/usr/bin/env python
"""Given a zoom level and a .poly file, enumerate all (x,y,z) tiles within
the region. Should correctly handle irregular polygons, i.e. not a simple
rectangular bounding box. Output can be fed into make_static_tiles.py to
create z/x/y.json files in bulk.
"""
import argparse
import math

import shapely
from shapely import Polygon


# standard tile to coordinates and reverse versions from
# https://wiki.openstreetmap.org/wiki/Slippy_map_tilenames
def deg2num(lat_deg, lon_deg, zoom):
    lat_rad = math.radians(lat_deg)
    n = 2.0 ** zoom
    xtile = int((lon_deg + 180.0) / 360.0 * n)
    ytile = int((1.0 - math.log(math.tan(lat_rad) + (1 / math.cos(lat_rad))) / math.pi) / 2.0 * n)
    return (xtile, ytile)

# This returns the NW-corner of the square. Use the function with xtile+1 and/or ytile+1 to get the other corners. With xtile+0.5 & ytile+0.5 it will return the center of the tile.
def num2deg(xtile, ytile, zoom):
    n = 2.0 ** zoom
    lon_deg = xtile / n * 360.0 - 180.0
    lat_rad = math.atan(math.sinh(math.pi * (1 - 2 * ytile / n)))
    lat_deg = math.degrees(lat_rad)
    return (lat_deg, lon_deg)


# code copied from https://wiki.openstreetmap.org/wiki/Osmosis/Polygon_Filter_File_Python_Parsing
def parse_poly(lines):
    """ Parse an Osmosis polygon filter file.

        Accept a sequence of lines from a polygon file, return a shapely.geometry.MultiPolygon object.

        http://wiki.openstreetmap.org/wiki/Osmosis/Polygon_Filter_File_Format
    """
    in_ring = False
    coords = []
    
    for (index, line) in enumerate(lines):
        if index == 0:
            # first line is junk.
            continue
        
        elif index == 1:
            # second line is the first polygon ring.
            coords.append([[], []])
            ring = coords[-1][0]
            in_ring = True
        
        elif in_ring and line.strip() == 'END':
            # we are at the end of a ring, perhaps with more to come.
            in_ring = False
    
        elif in_ring:
            # we are in a ring and picking up new coordinates.
            ring.append(list(map(float, line.split())))
    
        elif not in_ring and line.strip() == 'END':
            # we are at the end of the whole polygon.
            break
    
        elif not in_ring and line.startswith('!'):
            # we are at the start of a polygon part hole.
            coords[-1][1].append([])
            ring = coords[-1][1][-1]
            in_ring = True
    
        elif not in_ring:
            # we are at the start of a polygon part.
            coords.append([[], []])
            ring = coords[-1][0]
            in_ring = True
    
    return shapely.MultiPolygon(coords)


# based on https://gist.github.com/devdattaT/dd218d1ecdf6100bcf15
#get the range of tiles that intersect with the bounding box of the polygon	
def getTileRange(polygon, zoom):
	(xm, ym, xmx, ymx) = polygon.bounds
	starting = deg2num(ymx, xm, zoom)
	ending = deg2num(ym, xmx, zoom) # this will be the tiles containing the ending
	x_range = (starting[0], ending[0])
	y_range = (starting[1], ending[1])
	return (x_range, y_range)

#to get the tile as a polygon object
def getTileASpolygon(z,y,x):
	ymx, xm = num2deg(x, y, z)
	ym, xmx = num2deg(x + 1, y + 1, z)
	return Polygon([(xm, ym), (xmx, ym), (xmx, ymx), (xm, ymx)])


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('zoom', type=int)
    parser.add_argument('poly_file', type=str)
    args = parser.parse_args()

    with open(args.poly_file) as f:
        bounds_poly = parse_poly(f)
        (x_lo, x_hi),  (y_lo, y_hi) = getTileRange(bounds_poly, args.zoom)
        for x in range(x_lo, x_hi + 1):
            for y in range(y_lo, y_hi + 1):
                tile = getTileASpolygon(args.zoom, y, x)
                if bounds_poly.intersects(tile):
                    print(f"{x},{y},{args.zoom}")