# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

from django.urls import path
from .views import AppView

urlpatterns = [
    path('', AppView.as_view()),
]
