# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

import json
import os
import base64
import json
from http import HTTPStatus

from django.http import HttpResponse
from django.conf import settings


class UserParseMiddleware:
    """
    This middleware parses the user data from the incoming request headers.
    We use Azure App Service Easy Auth, which injects user claims to the request headers after login.
    """

    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        id_token = request.headers.get('X-Ms-Token-Aad-Id-Token')
        if id_token == None and settings.DEBUG:
            id_token = os.environ.get('X_MS_TOKEN_AAD_ID_TOKEN')

        if id_token == None:
            return HttpResponse('Unauthorized (missing user identification token)', status=HTTPStatus.UNAUTHORIZED)

        aad_user = aad_user_from_id_token(id_token)
        request.aad_user = aad_user

        return self.get_response(request)


def aad_user_from_id_token(id_token):
    aad_user = {'raw_claims': id_token}

    id_token_raw_split = id_token.split('.')

    if len(id_token_raw_split) > 2:
        token_props_base64 = id_token_raw_split[1]
        token_props_base64_bytes = token_props_base64.encode('utf-8')
        token_props_base64_bytes_padded = base64_pad(token_props_base64_bytes)
        token_props_bytes = base64.b64decode(token_props_base64_bytes_padded)
        token_props_string = token_props_bytes.decode('utf-8')
        parsed_claims = json.loads(token_props_string)

        aad_user['claims'] = parsed_claims
        aad_user['id'] = parsed_claims['oid']
        aad_user['email'] = parsed_claims['email']
        aad_user['name'] = parsed_claims['name']
        aad_user['preferred_username'] = parsed_claims['preferred_username']

    return aad_user


def base64_pad(string):
    pad = len(string) % 4
    return string + (b"="*pad)
