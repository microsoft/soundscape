# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

import os

from django.views.decorators.http import require_http_methods
from django.http import HttpResponse

from azure.storage.blob import BlobServiceClient, ContainerClient, StorageStreamDownloader, BlobProperties


ACCOUNT_URL = "https://{}.blob.core.windows.net/".format(os.environ.get('AZURE_STORAGE_ACCOUNT_NAME'))
CREDENTIAL = os.environ.get('AZURE_STORAGE_ACCOUNT_KEY')
CONTAINER_NAME = os.environ.get('AZURE_STORAGE_ACCOUNT_CONTAINER')
BLOB_PATH_PREFIX = os.environ.get('AZURE_STORAGE_ACCOUNT_LOCATION') + '/'


@require_http_methods(["GET"])
def files(_, resource):
    """Returns the requested file from the a path

    User generated files are stored in an Azure Storage account.
    This view is a proxy to that storage.
    """

    # Get the blob info
    blob_service_client: BlobServiceClient = BlobServiceClient(account_url=ACCOUNT_URL, credential=CREDENTIAL)
    container_client: ContainerClient = blob_service_client.get_container_client(CONTAINER_NAME)
    blob: StorageStreamDownloader = container_client.download_blob(BLOB_PATH_PREFIX + resource)
    blob_properties: BlobProperties = blob.properties

    # Get the blob content
    blob_content = blob.readall()

    # Respond with the requested blob file
    response = HttpResponse()
    response.content = blob_content

    if blob_properties.content_settings.cache_control:
        response.headers["Cache-Control"] = blob_properties.content_settings.cache_control
    if blob_properties.size:
        response.headers["Content-Length"] = blob_properties.size
    if blob_properties.content_settings.content_type:
        response.headers["Content-Type"] = blob_properties.content_settings.content_type
    if blob_properties.last_modified:
        response.headers["Last-Modified"] = blob_properties.last_modified
    if blob_properties.etag:
        response.headers["ETag"] = blob_properties.etag

    return response
