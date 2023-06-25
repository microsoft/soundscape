#!/usr/bin/env python3
"""Reads a stream of "[x, y, z]" lines from stdin, and generates z/x/y.json tile files
to the specified output directory.
"""
import argparse
import json
from pathlib import Path
import sys

import psycopg2
from psycopg2.extras import NamedTupleCursor

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
    return json.dumps(obj, sort_keys=True)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("output_dir", type=Path)
    parser.add_argument("postgres_dsn", type=str)
    args = parser.parse_args()

    conn = psycopg2.connect(args.postgres_dsn)
    cursor = conn.cursor(cursor_factory=NamedTupleCursor)

    for line in sys.stdin:
        x, y, z = line.strip()[1:-1].split(", ")
        tile_dir = args.output_dir / z / x
        tile_dir.mkdir(parents=True, exist_ok=True)
        tile_path = tile_dir / f"{y}.json"
        print(tile_path)
        with open(tile_path, "w") as f:
            f.write(tile(cursor, x, y, z))
