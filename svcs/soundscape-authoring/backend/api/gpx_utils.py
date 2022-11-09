# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

import os
import io
import requests
import enum

from django.db import transaction
from django.core.files import File
from django.core.files.images import ImageFile

import gpxpy
import gpxpy.gpx
import gpxpy.gpxfield

from .models import Activity, MediaType, WaypointGroup, Waypoint, ActivityType, WaypointMedia, WaypointGroupType

try:
    # Load LXML or fallback to cET or ET
    import lxml.etree as mod_etree  # type: ignore
except:
    try:
        import xml.etree.cElementTree as mod_etree  # type: ignore
    except:
        import xml.etree.ElementTree as mod_etree  # type: ignore

GPXSC = 'https://microsoft.com/Soundscape'
GPXSC_NS = '{gpxsc}'
GPXSC_NS_FULL = '{' + GPXSC + '}'

GPX_NSMAP = {
    'gpxtpx': 'https://www.garmin.com/xmlschemas/TrackPointExtension/v1',
    'gpxx': 'https://www.garmin.com/xmlschemas/GpxExtensions/v3',
    'gpxsc': GPXSC
}


class GPXVersion(enum.Enum):
    """
    Initial version.
    Activity Waypoints -> GPX Waypoints.
    """
    v1 = 1
    """
    Added support for activity POIs.
    Activity Waypoints -> GPX Route Points.
    Activity POIs -> GPX Waypoints.
    """
    v2 = 2


class WaypointType(enum.Enum):
    waypoint = 1
    routePoint = 2
    trackPoint = 3

def activity_to_gpx(activity: Activity) -> str:
    if activity.type == ActivityType.ORIENTEERING:
        version = GPXVersion.v1
    else:
        version = GPXVersion.v2

    gpx = gpxpy.gpx.GPX()

    gpx.nsmap = GPX_NSMAP
    gpx.creator = 'Microsoft Soundscape Authoring Tool'

    if activity.name:
        gpx.name = activity.name

    if activity.description:
        gpx.description = activity.description

    if activity.author_name:
        gpx.author_name = activity.author_name

    if activity.author_email:
        gpx.author_email = activity.author_email

    if activity.updated:
        gpx.time = activity.updated

    image_url = activity.image_url
    if image_url:
        gpx.link = image_url
        gpx.link_type = 'image'
        if activity.image_alt:
            gpx.link_text = activity.image_alt

    gpxsc_meta = mod_etree.Element(GPXSC_NS + 'meta')

    if activity.start:
        gpxsc_meta.attrib['start'] = gpxpy.gpxfield.format_time(activity.start)

    if activity.end:
        gpxsc_meta.attrib['end'] = gpxpy.gpxfield.format_time(activity.end)

    if hasattr(activity, 'expires'):
        gpxsc_meta.attrib['expires'] = 'true' if activity.expires else 'false'

    if activity.id:
        elem_id = mod_etree.SubElement(gpxsc_meta, GPXSC_NS + 'id')
        elem_id.text = str(activity.id)

    if activity.locale:
        elem_locale = mod_etree.SubElement(gpxsc_meta, GPXSC_NS + 'locale')
        elem_locale.text = activity.locale

    elem_behavior = mod_etree.SubElement(gpxsc_meta, GPXSC_NS + 'behavior')

    if version == GPXVersion.v1:
        elem_behavior.text = 'ScavengerHunt'
    else:
        elem_behavior.text = activity.type

    elem_version = mod_etree.SubElement(gpxsc_meta, GPXSC_NS + 'version')
    elem_version.text = str(version.value)

    gpx.metadata_extensions.append(gpxsc_meta)

    if version == GPXVersion.v1:
        # Waypoints
        if activity.waypoints_group is not None:
            waypoints = activity.waypoints_group.waypoints
            for waypoint in waypoints:
                gpx_wps = waypoint_to_gpx(waypoint)
                gpx.waypoints.append(gpx_wps)
    else:
        # Waypoints
        if activity.waypoints_group is not None:
            gpx_rte = gpxpy.gpx.GPXRoute()

            waypoints = activity.waypoints_group.waypoints
            for waypoint in waypoints:
                gpx_rtept = waypoint_to_gpx(waypoint, type=WaypointType.routePoint)
                gpx_rte.points.append(gpx_rtept)

            gpx.routes.append(gpx_rte)

        # POIs
        if activity.pois_group is not None:
            pois = activity.pois_group.waypoints
            for poi in pois:
                gpx_wps = waypoint_to_gpx(poi, type=WaypointType.waypoint)
                gpx.waypoints.append(gpx_wps)

    return gpx.to_xml()

# TODO: Import the new v2 scheme


def waypoint_to_gpx(waypoint: Waypoint, type: WaypointType = WaypointType.waypoint) -> gpxpy.gpx.GPXWaypoint:
    if type == WaypointType.waypoint:
        gpx_wps = gpxpy.gpx.GPXWaypoint()
    elif type == WaypointType.routePoint:
        gpx_wps = gpxpy.gpx.GPXRoutePoint()
    elif type == WaypointType.trackPoint:
        gpx_wps = gpxpy.gpx.GPXTrackPoint()

    gpx_wps.latitude = waypoint.latitude
    gpx_wps.longitude = waypoint.longitude

    if waypoint.name:
        gpx_wps.name = waypoint.name

    if waypoint.description:
        gpx_wps.description = waypoint.description

    if waypoint.departure_callout or waypoint.arrival_callout:
        gpxsc_annotations = mod_etree.Element(GPXSC_NS + 'annotations')

        if waypoint.departure_callout:
            elem_departure = mod_etree.SubElement(gpxsc_annotations, GPXSC_NS + 'annotation')
            elem_departure.attrib['type'] = 'departure'
            elem_departure.text = waypoint.departure_callout

        if waypoint.arrival_callout:
            elem_arrival = mod_etree.SubElement(gpxsc_annotations, GPXSC_NS + 'annotation')
            elem_arrival.attrib['type'] = 'arrival'
            elem_arrival.text = waypoint.arrival_callout

        gpx_wps.extensions.append(gpxsc_annotations)

    images = waypoint.images
    audio_clips = waypoint.audio_clips

    if len(images) > 0 or len(audio_clips) > 0:
        gpxsc_links = mod_etree.Element(GPXSC_NS + 'links')

        for image in images:
            elem_link = mod_etree.SubElement(gpxsc_links, GPXSC_NS + 'link')
            elem_link.attrib['href'] = image.media_url

            elem_text = mod_etree.SubElement(elem_link, 'text')
            elem_text.text = image.description

            elem_type = mod_etree.SubElement(elem_link, 'type')
            elem_type.text = image.mime_type

        for audio_clip in audio_clips:
            elem_link = mod_etree.SubElement(gpxsc_links, GPXSC_NS + 'link')
            elem_link.attrib['href'] = audio_clip.media_url

            elem_text = mod_etree.SubElement(elem_link, 'text')
            elem_text.text = audio_clip.description

            elem_type = mod_etree.SubElement(elem_link, 'type')
            elem_type.text = audio_clip.mime_type

        gpx_wps.extensions.append(gpxsc_links)

    return gpx_wps


@transaction.atomic
def gpx_to_activity(gpx_file: str, user) -> Activity:
    user_id = user.get('id')
    if user_id == None:
        raise Exception("GPX import error: missing required user ID")

    gpx = gpxpy.parse(gpx_file)
    if gpx == None:
        raise Exception("GPX import error: invalid GPX file")

    activity = Activity()
    activity.author_id = user_id

    # Metadata
    if gpx.author_name:
        activity.author_name = gpx.author_name
    else:
        raise Exception("GPX import error: missing required field 'author_name'")

    if gpx.author_email:
        activity.author_email = gpx.author_email

    if gpx.name:
        activity.name = gpx.name
    else:
        raise Exception("GPX import error: missing required field 'name'")

    if gpx.description:
        activity.description = gpx.description
    else:
        raise Exception("GPX import error: missing required field 'description'")

    if gpx.time:
        activity.updated = gpx.time

    # Image
    if gpx.link and gpx.link_type == 'image':
        # Wait for image to download...
        image_response = requests.get(gpx.link)

        if image_response.status_code == 200 and image_response.content != None:
            filename = os.path.basename(gpx.link)
            activity.image = ImageFile(io.BytesIO(image_response.content), name=filename)

            if gpx.link_text:
                activity.image_alt = gpx.link_text

    # Metadata extensions
    gpxsc_meta = next((e for e in gpx.metadata_extensions if e.tag == (GPXSC_NS_FULL + 'meta')), None)

    version = GPXVersion.v1

    if gpxsc_meta != None:
        if gpxsc_meta.get('expires'):
            activity.expires = bool(gpxsc_meta.get('expires'))

        if gpxsc_meta.get('start', None):
            activity.start = gpxpy.gpxfield.parse_time(gpxsc_meta.get('start'))

        if gpxsc_meta.get('end', None):
            activity.end = gpxpy.gpxfield.parse_time(gpxsc_meta.get('end'))

        for sub_element in gpxsc_meta:
            if sub_element.tag == GPXSC_NS_FULL + 'locale':
                activity.locale = sub_element.text
            elif sub_element.tag == GPXSC_NS_FULL + 'behavior':
                activity.type = sub_element.text
            elif sub_element.tag == GPXSC_NS_FULL + 'version':
                version = GPXVersion(int(sub_element.text))

    activity.save()

    # Waypoint Groups
    waypoints_group = WaypointGroup(activity=activity, name='Default', type=WaypointGroupType.ORDERED)
    waypoints_group.save()

    pois_group = WaypointGroup(activity=activity, name='Points of Interest', type=WaypointGroupType.UNORDERED)
    pois_group.save()

    if version == GPXVersion.v1:
        # Waypoints
        if len(gpx.waypoints) > 0:
            for index, gpx_waypoint in enumerate(gpx.waypoints):
                waypoint = gpx_to_waypoint(gpx_waypoint, waypoints_group)
                waypoint.index = index
                waypoint.save()
    else:
        # Waypoints
        if len(gpx.routes) > 0:
            for index, gpx_route_point in enumerate(gpx.routes[0].points):
                waypoint = gpx_to_waypoint(gpx_route_point, waypoints_group)
                waypoint.index = index
                waypoint.save()
        # POIs
        if len(gpx.waypoints) > 0:
            for index, gpx_waypoint in enumerate(gpx.waypoints):
                waypoint = gpx_to_waypoint(gpx_waypoint, pois_group)
                waypoint.save()

    return activity


def gpx_to_waypoint(gpx_waypoint: gpxpy.gpx.GPXWaypoint, waypoint_group: WaypointGroup) -> Waypoint:
    activity_waypoint = Waypoint(latitude=gpx_waypoint.latitude,
                                 longitude=gpx_waypoint.longitude,
                                 group=waypoint_group,
                                 name=gpx_waypoint.name)
    activity_waypoint.description = gpx_waypoint.description

    gpxsc_annotations = next((e for e in gpx_waypoint.extensions if e.tag == (GPXSC_NS_FULL + 'annotations')), None)

    if gpxsc_annotations != None:
        for sub_element in gpxsc_annotations:
            if sub_element.attrib.get('type') == 'arrival':
                activity_waypoint.arrival_callout = sub_element.text
            elif sub_element.attrib.get('type') == 'departure':
                activity_waypoint.departure_callout = sub_element.text

    gpxsc_links = next((e for e in gpx_waypoint.extensions if e.tag == (GPXSC_NS_FULL + 'links')), None)

    # Waypoint Media
    if gpxsc_links != None:
        activity_waypoint.save()

        for gpxsc_link in gpxsc_links:
            href = gpxsc_link.attrib.get('href')
            if href == None:
                continue

            media_response = requests.get(href)

            if media_response.status_code != 200 or media_response.content == None:
                continue

            filename = os.path.basename(href)
            media = File(io.BytesIO(media_response.content), name=filename)

            mime_type_element = next((e for e in gpxsc_link if e.tag == 'type'), None)
            if mime_type_element == None:
                continue

            if mime_type_element.text.startswith('image'):
                type = MediaType.IMAGE
            elif mime_type_element.text.startswith('audio'):
                type = MediaType.AUDIO
            else:
                continue

            description_element = next((e for e in gpxsc_link if e.tag == 'text'), None)

            waypoint_media = WaypointMedia(waypoint=activity_waypoint,
                                           media=media,
                                           type=type,
                                           mime_type=mime_type_element.text,
                                           description=description_element.text)
            waypoint_media.save()

    return activity_waypoint
