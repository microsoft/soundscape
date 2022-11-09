# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

import os

from django.http import HttpResponse
from django.core.exceptions import ValidationError
from django.core.files.base import ContentFile
from django.db import transaction
from django.utils import timezone

from rest_framework.viewsets import ModelViewSet
from rest_framework.exceptions import APIException
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.serializers import ValidationError

from .models import Waypoint, WaypointGroup, WaypointMedia, MediaType, Activity, WaypointGroupType
from .serializers import ActivityListSerializer, ActivityDetailSerializer, WaypointGroupSerializer, WaypointSerializer, WaypointMediaSerializer
from .model_utils import duplicate_activity, shift_waypoints_after_delete
from .gpx_utils import activity_to_gpx, gpx_to_activity

def gpx_response(content, filename):
    response = HttpResponse(content, content_type='application/gpx+xml')
    response['Content-Disposition'] = 'attachment; filename="{0}.gpx"'.format(filename)
    return response


class ActivityViewSet(ModelViewSet):
    queryset = Activity.objects.all()

    def get_queryset(self):
        user_id = self.request.aad_user['id']
        if user_id == None:
            raise ValidationError('Missing user id')
        queryset = Activity.objects.filter(author_id=user_id)
        return queryset

    def get_serializer_class(self):
        if self.action == 'list':
            return ActivityListSerializer
        return ActivityDetailSerializer

    def perform_create(self, serializer):
        # Make sure the user id is valid and append it to the activity
        user_id = self.request.aad_user['id']
        if user_id == None:
            raise ValidationError('Missing user id')

        with transaction.atomic():
            instance = serializer.save(author_id=user_id)
            # Create default empty waypoint groups
            WaypointGroup(activity=instance, name='Default', type=WaypointGroupType.ORDERED).save()
            WaypointGroup(activity=instance, name='Points of Interest', type=WaypointGroupType.UNORDERED).save()

    @action(detail=True, methods=['POST'], name='Duplicate')
    def duplicate(self, request, pk=None):
        activity = Activity.objects.get(id=pk)
        duplicated = duplicate_activity(activity)

        queryset = Activity.objects.get(id=duplicated.id)
        serializer = self.get_serializer(queryset, many=False)
        return Response(serializer.data)

    @action(detail=True, methods=['POST'], name='Publish')
    def publish(self, request, pk=None):
        activity: Activity = Activity.objects.get(id=pk)

        content = activity_to_gpx(activity)
        content_bytes = bytes(content, 'utf-8')
        content_file = ContentFile(content_bytes)

        activity.storePublishedFile(content_file)

        activity.last_published = timezone.now()
        activity.unpublished_changes = False
        activity.save(update_fields=['last_published', 'unpublished_changes'])

        queryset = Activity.objects.get(id=activity.id)
        serializer = self.get_serializer(queryset, many=False)
        return Response(serializer.data)

    @action(detail=True, methods=['GET'], name='Export GPX')
    def export_gpx(self, request, pk=None):
        activity = Activity.objects.get(id=pk)
        content = activity_to_gpx(activity)
        return gpx_response(content, activity.name)

    @action(detail=False, methods=['POST'], name='Import GPX')
    def import_gpx(self, request):
        gpx = request.FILES.get('gpx')
        if gpx == None:
            raise ValidationError('Missing GPX file')

        user = self.request.aad_user
        if user == None:
            raise ValidationError('Missing user')

        try:
            activity: Activity = gpx_to_activity(gpx, user)
        except:
            raise ValidationError(
                'Invalid activity. Please use a previously exported GPX file containing the activity.')

        serializer = self.get_serializer(activity, many=False)
        return Response(serializer.data)


class WaypointGroupViewSet(ModelViewSet):
    queryset = WaypointGroup.objects.all()
    serializer_class = WaypointGroupSerializer


class WaypointViewSet(ModelViewSet):
    queryset = Waypoint.objects.all()
    serializer_class = WaypointSerializer

    # Lifecycle

    def perform_create(self, serializer):
        with transaction.atomic():
            group: WaypointGroup = serializer.validated_data['group']
            if group.type == WaypointGroupType.ORDERED:
                newWaypointIndex = group.newWaypointIndex
                serializer.save(index=newWaypointIndex)
            else:
                serializer.save()

            self.saveMedia(serializer=serializer)

    def saveMedia(self, serializer):
        # Images
        images = self.request.FILES.getlist('images[]')
        image_alts = self.request.data.getlist('image_alts[]')

        for i, image in enumerate(images):
            image_alt = image_alts[i]
            WaypointMedia(waypoint=serializer.instance,
                          media=image,
                          type=MediaType.IMAGE,
                          mime_type=image.content_type,
                          description=image_alt,
                          index=i).save()

        # Audio clips
        audio_clips = self.request.FILES.getlist('audio_clips[]')
        audio_clip_texts = self.request.data.getlist('audio_clip_texts[]')

        for i, audio_clip in enumerate(audio_clips):
            audio_clip_text = audio_clip_texts[i]
            WaypointMedia(waypoint=serializer.instance,
                          media=audio_clip,
                          type=MediaType.AUDIO,
                          mime_type=audio_clip.content_type,
                          description=audio_clip_text,
                          index=i).save()

    @transaction.atomic
    def perform_update(self, serializer):
        group = serializer.instance.group

        if group.type == WaypointGroupType.UNORDERED:
            # No need to update index, save.
            serializer.save()
            self.saveMedia(serializer=serializer)
            return

        current_index = serializer.instance.index
        updated_index = serializer.validated_data['index']

        if current_index == updated_index:
            # No need to update index, save.
            serializer.save()
            self.saveMedia(serializer=serializer)
            return

        if updated_index < 0:
            raise APIException("Waypoint index cannot be lower than 0")

        if abs(current_index - updated_index) != 1:
            raise APIException("At the moment a waypoint index can only be increased or decreased by 1")

        other_waypoint = Waypoint.objects.get(group=group, index=updated_index)

        if other_waypoint == None:
            serializer.save()
            self.saveMedia(serializer=serializer)
        else:
            # Swap between waypoint indexes
            # Temporarily set the other waypoint to -1 to avoid the error:
            # django.db.utils.IntegrityError: duplicate key value violates unique constraint "unique_group_index"
            other_waypoint.index = -1
            other_waypoint.save()

            serializer.save()
            self.saveMedia(serializer=serializer)

            other_waypoint.index = current_index
            other_waypoint.save()

    def perform_destroy(self, instance):
        group: WaypointGroup = instance.group
        deleted_index = instance.index

        instance.delete()

        if group.type == WaypointGroupType.ORDERED:
            shift_waypoints_after_delete(group, deleted_index)


class WaypointMediaViewSet(ModelViewSet):
    queryset = WaypointMedia.objects.all()
    serializer_class = WaypointMediaSerializer
