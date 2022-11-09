# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

import os
import json

from django.http import JsonResponse


def auth_me_file():
    auth_me_filepath = os.path.join(os.path.dirname(os.path.dirname(__file__)), '.auth', 'me.json')
    try:
        file = open(auth_me_filepath, 'r')
        auth_me_json = json.load(file)
        file.close()
        return auth_me_json
    except FileNotFoundError:
        raise Exception('Missing auth file. In development, we need to simulate the Azure Auth file. Path: /.auth/me.json')


AUTH_ME_JSON = auth_me_file()


def auth_me(request):
    return JsonResponse(AUTH_ME_JSON, safe=False)
