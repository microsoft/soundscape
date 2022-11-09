# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

import os
import requests
from http import HTTPStatus
from django.views.decorators.http import require_http_methods
from django.http import HttpResponse

AZURE_MAPS_SUBSCRIPTION_KEY = os.environ.get('AZURE_MAPS_SUBSCRIPTION_KEY')
if AZURE_MAPS_SUBSCRIPTION_KEY == None:
    raise Exception('Invalid Azure Maps subscription key')


@require_http_methods(["GET"])
def map(request):
    """
    Returns a map tile from Azure Maps.

    Soundscape Authoring is a publicly exposed application, so we use server-to-server
    access to Azure Maps REST APIs so the subscription key can be securely stored.

    More info: https://docs.microsoft.com/en-us/rest/api/maps/render-v2/get-map-tile 
    """
    x = request.GET.get('x')
    y = request.GET.get('y')
    zoom = request.GET.get('zoom')

    if x == None or y == None or zoom == None:
        return HttpResponse('Missing required parameters', status=HTTPStatus.BAD_REQUEST)

    tileset_id = request.GET.get('tileset_id', "microsoft.base.road")
    tile_size = request.GET.get('tile_size', "256")
    language = request.GET.get('language', "en-US")
    view = request.GET.get('view', "Auto")

    params = {
        'api-version': '2.1',
        'subscription-key': AZURE_MAPS_SUBSCRIPTION_KEY,
        'tilesetId': tileset_id,
        'tileSize': tile_size,
        'language': language,
        'view': view,
        'zoom': zoom,
        'x': x,
        'y': y
    }

    tile_response = requests.get("https://atlas.microsoft.com/map/tile", params)

    response = HttpResponse()
    response.status_code = tile_response.status_code
    response.content = tile_response.content

    for header_key in ["Cache-Control", "Content-Length", "Content-Type", "Date", "ETag", "Expires"]:
        header_value = tile_response.headers.get(header_key)
        if header_value != None:
            response.headers[header_key] = header_value

    return response
