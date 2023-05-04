"""
This is a minimal shim to replace missing code referenced by ingest.py.
"""
from psycopg2.extensions import make_dsn, parse_dsn

class SoundscapeKube:
    def __init__(self, arg1, arg2):
        self.databases = {
            'osm': {
                'dbstatus': None,
                'name': 'osm',
                'dsn2': make_dsn(host="postgis", port=5432, dbname="osm", user="postgres", password="secret"),
            }
        }

    def connect(self):
        pass

    def enumerate_databases(self):
        return self.databases.values()

    def get_database_status(self, db_name):
        return self.databases[db_name]['dbstatus']

    def set_database_status(self, db_name, status):
        self.databases[db_name]['dbstatus'] = status

    def get_url_dsn(self, dsn):
        args = parse_dsn(dsn)
        user = args.get('user', '')
        password = args.get('password', '')
        host = args.get('host', '')
        port = args.get('port', '')
        dbname = args.get('dbname', '')
        return f"postgis://{user}:{password}@{host}:{port}/{dbname}"
