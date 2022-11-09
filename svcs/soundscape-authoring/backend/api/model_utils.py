# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

from .models import Activity, WaypointGroup, Waypoint, WaypointMedia
from django.db import transaction


@transaction.atomic
def duplicate_activity(activity: Activity) -> Activity:
    waypoint_groups = activity.waypoint_groups_all

    # TODO: duplicate featured image
    activity.name = '{} copy'.format(activity.name)
    activity.pk = None
    activity.id = None
    activity.last_published = None
    activity.unpublished_changes = None
    activity._state.adding = True
    activity.save()

    for group in waypoint_groups.iterator():
        duplicate_waypoint_group(group=group, activity=activity)

    return activity


@transaction.atomic
def duplicate_waypoint_group(group: WaypointGroup, activity: Activity):
    waypoints = group.waypoints

    group.activity = activity
    group.pk = None
    group.id = None
    group._state.adding = True
    group.save()

    for waypoint in waypoints.iterator():
        duplicate_waypoint(waypoint=waypoint, group=group)

# TODO: support waypoint media


def duplicate_waypoint(waypoint: Waypoint, group: WaypointGroup):
    waypoint_media_items = waypoint.media_items

    waypoint.group = group
    waypoint.pk = None
    waypoint.id = None
    waypoint._state.adding = True
    waypoint.save()

    for waypoint_media in waypoint_media_items.iterator():
        duplicate_waypoint_media(waypoint_media=waypoint_media, waypoint=waypoint)


@transaction.atomic
def duplicate_waypoint_media(waypoint_media: WaypointMedia, waypoint: Waypoint):
    waypoint_media.waypoint = waypoint
    waypoint_media.pk = None
    waypoint_media.id = None
    waypoint_media._state.adding = True
    waypoint_media.save()


def shift_waypoints_after_delete(group: WaypointGroup, deleted_index: int):
    # Get all waypoints after the deleted index
    greater_waypoints = Waypoint.objects.filter(group=group, index__gt=deleted_index)

    # Decrease their index
    for waypoint in greater_waypoints.iterator():
        waypoint.index -= 1
        waypoint.save()
