# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

from django.http import HttpResponse
from http import HTTPStatus
from api.models import UserPermissions


class UserAllowlistMiddleware:
    """
    This middleware makes sure the user is allowed to view the webpage.
    """

    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        if request.aad_user == None:
            return HttpResponse('Unauthorized (missing user credentials)', status=HTTPStatus.UNAUTHORIZED)

        user_email = request.aad_user['email'].lower()

        try:
            user_permissions = UserPermissions.objects.get(user_email=user_email)
        except:
            user_permissions = None

        if user_permissions == None:
            user_permissions = UserPermissions(user_email=user_email, allow_app=False, allow_api=False)
            user_permissions.save()
            return HttpResponse('You do not have access to this webpage<br>{}<br><a href="/.auth/logout">Logout</a>'.format(user_email), status=HTTPStatus.FORBIDDEN)

        if user_permissions.allow_app == False:
            return HttpResponse('You do not have access to this webpage<br>{}<br><a href="/.auth/logout">Logout</a>'.format(user_email), status=HTTPStatus.FORBIDDEN)

        return self.get_response(request)
