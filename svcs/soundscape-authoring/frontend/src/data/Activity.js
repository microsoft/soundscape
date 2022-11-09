// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

import Waypoint from './Waypoint';
import WaypointsGroup from './WaypointsGroup';

export default class Activity {
  static TYPE = Object.freeze({
    ORIENTEERING: 'Orienteering',
    GUIDED_TOUR: 'GuidedTour',
  });

  constructor(data) {
    Object.assign(this, data);

    if (data.waypoints_group) {
      this.waypoints_group = new WaypointsGroup(data.waypoints_group);
    }

    if (data.pois_group) {
      this.pois_group = new WaypointsGroup(data.pois_group);
    }
  }

  waypointGroupByType(waypointType) {
    switch (waypointType) {
      case Waypoint.TYPE.WAYPOINT:
        return this.waypoints_group;
      case Waypoint.TYPE.POI:
        return this.pois_group;
      default:
        return null;
    }
  }
}
