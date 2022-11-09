# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

import os
import uuid

from django.db import models
from django.db.models.signals import pre_save, post_delete
from django.dispatch import receiver
from django.utils.translation import gettext_lazy as _
from django.core.files.storage import default_storage

# Constants
geographic_decimal_places = 6
geographic_digits = geographic_decimal_places + 3

RELATIVE_FILE_URL = os.environ.get('AZURE_STORAGE_ACCOUNT_RELATIVE_FILE_URL')

# Helpers


def activityImageStorageName(instance, filename):
   # activities/{activity_id}/featured_image.ext
    _, ext = os.path.splitext(filename)
    updated_filename = 'featured_image' + ext
    return os.path.join(instance.file_directory_path, updated_filename)


def waypointMediaStorageName(instance, filename):
    # activities/{activity_id}/media/filename.ext
    _, ext = os.path.splitext(filename)
    updated_filename = str(instance.id) + ext
    return os.path.join(instance.waypoint.group.activity.waypoints_media_directory_path, updated_filename)


def waypointImageStorageName(instance, filename):
    """Deprecated. Keep for migration history."""

    # waypoints/{waypoint_id}/featured_image.ext
    ext = filename.split('.')[-1]
    updated_filename = 'featured_image.{}'.format(ext)
    return os.path.join('waypoints', str(instance.id), updated_filename)


def file_proxy_url(file: models.FileField):
    """
    Used for serving files from a storage account.
    Not applicable in a local environment.
    """
    if file == None or len(file.name) == 0:
        return None

    return file.url


class ActivityType(models.TextChoices):
    ORIENTEERING = 'Orienteering', _('Orienteering')
    GUIDED_TOUR = 'GuidedTour', _('Guided Tour')


class WaypointGroupType(models.TextChoices):
    ORDERED = 'ordered', _('Ordered')
    UNORDERED = 'unordered', _('Unordered')
    GEOFENCE = 'geofence', _('Geofence')


class MediaType(models.TextChoices):
    IMAGE = 'image', _('Image')
    AUDIO = 'audio', _('Audio')
    VIDEO = 'video', _('Video')


class Locale(models.TextChoices):
    EN_US = 'en_US', _('English (United States)')

# Models


class CommonModel(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4)
    created = models.DateTimeField(auto_now_add=True)
    updated = models.DateTimeField(auto_now=True)

    class Meta:
        abstract = True


class Activity(CommonModel):
    author_id = models.CharField(max_length=36)
    author_email = models.EmailField(blank=True, null=True)
    author_name = models.TextField()
    name = models.TextField()
    description = models.TextField()
    type = models.CharField(max_length=20, choices=ActivityType.choices, default=ActivityType.ORIENTEERING)
    locale = models.CharField(max_length=20, choices=Locale.choices, default=Locale.EN_US)
    start = models.DateTimeField(blank=True, null=True)
    end = models.DateTimeField(blank=True, null=True)
    expires = models.BooleanField(default=False)
    image = models.ImageField(blank=True, null=True, upload_to=activityImageStorageName)
    image_alt = models.TextField(blank=True, null=True)
    last_published = models.DateTimeField(blank=True, null=True)
    unpublished_changes = models.BooleanField(default=False)

    class Meta:
        ordering = ['-created']

    def __str__(self):
        return self.name

    @receiver(pre_save)
    def checker(sender, instance, raw, using, update_fields, *args, **kwargs):
        if isinstance(instance, Activity) == False:
            return

        if update_fields is None or 'unpublished_changes' not in update_fields:
            instance.unpublished_changes = True

    @receiver(post_delete)
    def delete_file(sender, instance, **kwargs):
        if isinstance(instance, Activity) == False:
            return

        instance.deletePublishedFile()
        instance.deleteFeaturedImageFile()
        instance.deleteWaypointsMediaDirectory()
        instance.deleteFileDirectory()

    @property
    def file_directory_path(self):
        return os.path.join('activities', str(self.id))

    @property
    def gpx_file_path(self):
        return os.path.join(self.file_directory_path, 'activity.gpx')

    @property
    def waypoints_media_directory_path(self):
        return os.path.join(self.file_directory_path, 'waypoints_media')

    @property
    def can_link(self):
        return self.last_published != None

    @property
    def waypoint_groups_all(self):
        return WaypointGroup.objects.filter(activity=self)

    def waypoint_groups(self, type: WaypointGroupType):
        return self.waypoint_groups_all.filter(type=type)

    @property
    def waypoints_group(self):
        return self.waypoint_groups(type=WaypointGroupType.ORDERED).first()

    @property
    def pois_group(self):
        return self.waypoint_groups(type=WaypointGroupType.UNORDERED).first()

    @property
    def image_url(self):
        return file_proxy_url(self.image)

    def child_entity_did_update(self):
        self.unpublished_changes = True
        self.save()
        pass

    def storePublishedFile(self, content):
        self.deletePublishedFile()
        default_storage.save(self.gpx_file_path, content)

    def deletePublishedFile(self):
        if default_storage.exists(self.gpx_file_path):
            default_storage.delete(self.gpx_file_path)

    def deleteFeaturedImageFile(self):
        if self.image and default_storage.exists(self.image.path):
            default_storage.delete(self.image.path)

    def deleteWaypointsMediaDirectory(self):
        if default_storage.exists(self.waypoints_media_directory_path):
            default_storage.delete(self.waypoints_media_directory_path)

    def deleteFileDirectory(self):
        if default_storage.exists(self.file_directory_path):
            default_storage.delete(self.file_directory_path)


class WaypointGroup(CommonModel):
    activity = models.ForeignKey(Activity, on_delete=models.CASCADE)
    name = models.TextField(blank=True, null=True)
    type = models.CharField(max_length=50, choices=WaypointGroupType.choices, default=WaypointGroupType.ORDERED)

    class Meta:
        ordering = ['-created']

    def __str__(self):
        return '{0} ({1})'.format(self.name, self.activity.name)

    @receiver(pre_save)
    def checker(sender, instance, raw, using, update_fields, *args, **kwargs):
        if isinstance(instance, WaypointGroup) == False:
            return

        instance.activity.child_entity_did_update()

    @property
    def waypoints(self):
        return Waypoint.objects.filter(group=self)

    @property
    def newWaypointIndex(self):
        if self.type != WaypointGroupType.ORDERED:
            return None

        try:
            latest_waypoint = Waypoint.objects.filter(group=self).latest('index')
        except:
            return 0

        return latest_waypoint.index+1


class Waypoint(CommonModel):
    latitude = models.DecimalField(decimal_places=geographic_decimal_places, max_digits=geographic_digits)
    longitude = models.DecimalField(decimal_places=geographic_decimal_places, max_digits=geographic_digits)

    group = models.ForeignKey(WaypointGroup, on_delete=models.CASCADE)
    index = models.IntegerField(blank=True, null=True)  # Index is only applicable when used in an ordered group

    name = models.TextField()
    description = models.TextField(blank=True, null=True)
    departure_callout = models.TextField(blank=True, null=True)
    arrival_callout = models.TextField(blank=True, null=True)

    class Meta:
        ordering = ['index']
        constraints = [
            models.UniqueConstraint(fields=["group", "index"], name="unique_group_index")
        ]

    def __str__(self):
        return '{0}. {1} ({2},{3})'.format(self.index, self.name, self.latitude, self.longitude)

    @receiver(pre_save)
    def checker(sender, instance, raw, using, update_fields, *args, **kwargs):
        if isinstance(instance, Waypoint) == False:
            return

        activity = instance.group.activity
        activity.child_entity_did_update()

    @property
    def type(self):
        return self.group.type

    @property
    def media_items(self):
        return WaypointMedia.objects.filter(waypoint=self)

    @property
    def images(self):
        return WaypointMedia.objects.filter(waypoint=self, type=MediaType.IMAGE)

    @property
    def audio_clips(self):
        return WaypointMedia.objects.filter(waypoint=self, type=MediaType.AUDIO)


class WaypointMedia(CommonModel):
    waypoint = models.ForeignKey(Waypoint, on_delete=models.CASCADE)
    media = models.FileField(upload_to=waypointMediaStorageName)
    type = models.CharField(max_length=20, choices=MediaType.choices)
    mime_type = models.TextField()
    description = models.TextField(blank=True, null=True)  # For images, this is the alt text
    index = models.IntegerField(blank=True, null=True)

    class Meta:
        ordering = ['index']

    @receiver(pre_save)
    def checker(sender, instance, raw, using, update_fields, *args, **kwargs):
        if isinstance(instance, WaypointMedia) == False:
            return

        activity = instance.waypoint.group.activity
        activity.child_entity_did_update()

    @receiver(post_delete)
    def delete_file(sender, instance, **kwargs):
        if isinstance(instance, WaypointMedia) == False:
            return

        instance.delete_media_file()

    @property
    def media_url(self):
        return file_proxy_url(self.media)

    def delete_media_file(self):
        if self.media and default_storage.exists(self.media.path):
            default_storage.delete(self.media.path)


class UserPermissions(models.Model):
    user_email = models.EmailField(unique=True)
    allow_app = models.BooleanField(default=False)
    allow_api = models.BooleanField(default=False)

    def __str__(self):
        return '{0} allow app: {1}, allow api {2}'.format(self.user_email, self.allow_app, self.allow_api)
