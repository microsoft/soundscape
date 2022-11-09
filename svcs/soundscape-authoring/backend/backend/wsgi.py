# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

"""
WSGI config for backend project.

It exposes the WSGI callable as a module-level variable named ``application``.

For more information on this file, see
https://docs.djangoproject.com/en/3.2/howto/deployment/wsgi/
"""

import os

from django.core.wsgi import get_wsgi_application

application = get_wsgi_application()
