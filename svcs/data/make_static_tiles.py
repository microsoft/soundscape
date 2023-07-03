#!/usr/bin/env python3
"""Reads a stream of "x,y,z" lines from stdin (such as the output of
enumerate_tiles.py), and generates z/x/y.json tile files to the specified
output directory.
"""
import argparse
import json
from pathlib import Path
import sys

import psycopg2
from psycopg2.extras import NamedTupleCursor

import bz2

tile_query = """
    SELECT * from soundscape_tile(%(zoom)s, %(tile_x)s, %(tile_y)s)
"""

def tile(cursor, x, y, zoom):
    cursor.execute(tile_query, {'zoom': int(zoom), 'tile_x': x, 'tile_y': y})
    value = cursor.fetchall()
    obj = {
        'type': 'FeatureCollection',
        'features': list(map(lambda x: x._asdict(), value))
    }
    if len(obj["features"]) == 0:
        return None
    return json.dumps(obj, sort_keys=True)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("output_dir", type=Path)
    parser.add_argument("postgres_dsn", type=str)
    args = parser.parse_args()

    conn = psycopg2.connect(args.postgres_dsn)
    cursor = conn.cursor(cursor_factory=NamedTupleCursor)

    total_tiles = 0
    nonempty_tiles = 0
    for line in sys.stdin:
        total_tiles += 1
        x, y, z = line.strip().split(",")
        tile_dir = args.output_dir / z / x
        tile_path = tile_dir / f"{y}.json.bz2"
        if tile_path.exists():
            continue
        output = tile(cursor, x, y, z)
        if output:
            tile_dir.mkdir(parents=True, exist_ok=True)
            nonempty_tiles += 1
            with bz2.open(tile_path, "w") as f:
                f.write(output.encode())

    print(f"Tiles in region: {total_tiles}")
    print(f"Tiles with features: {nonempty_tiles}")
