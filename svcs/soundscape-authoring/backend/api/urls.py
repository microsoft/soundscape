# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

from django.urls import path, include
from rest_framework import routers
from .views import ActivityViewSet, WaypointGroupViewSet, WaypointMediaViewSet, WaypointViewSet, WaypointMediaViewSet

router = routers.DefaultRouter()
router.register(r'activities', ActivityViewSet)
router.register(r'waypoint_groups', WaypointGroupViewSet)
router.register(r'waypoints', WaypointViewSet)
router.register(r'waypoints_media', WaypointMediaViewSet)

urlpatterns = [
    path('v1/', include(router.urls)),
]
