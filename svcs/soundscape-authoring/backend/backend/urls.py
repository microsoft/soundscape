# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

"""backend URL Configuration

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/3.2/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""
import os

from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api-auth/', include('rest_framework.urls')),

    # Serve API app
    path('api/', include('api.urls')),

    # Serve map tiles app
    path('map/', include('map.urls')),

    # Serve frontend app
    path('', include('frontend.urls')),
]

# Serve user file uploads
if os.environ.get('ENV') == 'local':
    # In a local environment, this is used for storing and serving user file uploads.
    urlpatterns.extend(static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT))
else:
    # In a cloud environment, files are stored and served via the 'files' app.
    urlpatterns.append(path('files/', include('files.urls')))

# In debug, we simulate the Azure auth by serving the auth JSON locally.
if settings.DEBUG:
    from .views import auth_me
    urlpatterns.append(path('.auth/me', auth_me))
