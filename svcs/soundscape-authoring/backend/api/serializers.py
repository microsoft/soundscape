# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

from rest_framework import serializers

from .models import Activity, WaypointGroup, Waypoint, WaypointMedia


class WaypointMediaSerializer(serializers.ModelSerializer):
    media_url = serializers.URLField(read_only=True)

    class Meta:
        model = WaypointMedia
        fields = ['id', 'media_url', 'type', 'mime_type', 'description', 'index']


class WaypointSerializer(serializers.ModelSerializer):
    images = WaypointMediaSerializer(many=True, read_only=True)
    audio_clips = WaypointMediaSerializer(many=True, read_only=True)

    class Meta:
        model = Waypoint
        fields = ['id', 'latitude', 'longitude', 'group', 'type', 'index',
                  'name', 'description', 'departure_callout', 'arrival_callout', 'images', 'audio_clips']


class WaypointGroupSerializer(serializers.ModelSerializer):
    waypoints = WaypointSerializer(many=True, read_only=True)

    class Meta:
        model = WaypointGroup
        fields = ['id', 'activity', 'name', 'type', 'waypoints']


class ActivityListSerializer(serializers.ModelSerializer):
    image_url = serializers.URLField(read_only=True)

    class Meta:
        model = Activity
        fields = ['id', 'author_id', 'author_name', 'author_email', 'name', 'description',
                  'type', 'start', 'end', 'expires', 'image', 'image_url', 'image_alt']
        extra_kwargs = {
            'image': {'write_only': True},
            'image_url': {'read_only': True},
        }


class ActivityDetailSerializer(serializers.ModelSerializer):
    waypoints_group = WaypointGroupSerializer(read_only=True)
    pois_group = WaypointGroupSerializer(read_only=True)

    image_url = serializers.URLField(read_only=True)

    class Meta:
        model = Activity
        fields = ['id', 'author_id', 'author_name', 'author_email', 'name', 'description', 'type',
                  'start', 'end', 'expires', 'unpublished_changes', 'can_link', 'image', 'image_url', 'image_alt', 'waypoints_group', 'pois_group']
        extra_kwargs = {
            'image': {'write_only': True},
            'image_url': {'read_only': True},
        }
