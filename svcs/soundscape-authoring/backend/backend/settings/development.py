# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

import os
from .base import *

DEBUG = True

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': os.environ['PSQL_DB_NAME'],
        'USER': os.environ['PSQL_DB_USER'],
        'PASSWORD': os.environ['PSQL_DB_PASS'],
        'HOST': os.environ['PSQL_DB_HOST'],
        'PORT': os.environ['PSQL_DB_PORT'],
        'OPTIONS': {'sslmode': 'prefer'},
    }
}

# Database for storing files, such as images and GPX files
DEFAULT_FILE_STORAGE = 'storages.backends.azure_storage.AzureStorage'
AZURE_ACCOUNT_NAME = os.environ['AZURE_STORAGE_ACCOUNT_NAME']
AZURE_ACCOUNT_KEY = os.environ['AZURE_STORAGE_ACCOUNT_KEY']
AZURE_CONTAINER = os.environ['AZURE_STORAGE_ACCOUNT_CONTAINER']
AZURE_LOCATION = os.environ['AZURE_STORAGE_ACCOUNT_LOCATION']
