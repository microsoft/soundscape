"""
This is a minimal shim to replace missing code referenced by ingest.py.
"""

class SoundscapeKube:
    def __init__(self, arg1, arg2):
        self.databases = {
            'osm': {
                'dbstatus': None,
                'name': 'osm',
                'dsn2': 'host=postgis port=5432 dbname=osm user=postgres password=secret',
            }
        }

    def connect(self):
        pass

    def enumerate_databases(self):
        return self.databases.values()

    def get_database_status(self, db_name):
        return self.databases[db_name]['db_status']

    def set_database_status(self, db_name, status):
        self.databases[db_name]['db_status'] = status

    def get_url_dsn(self, arg1):
        pass