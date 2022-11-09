// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

import Waypoint from './Waypoint';

export default class WaypointsGroup {
  constructor(data) {
    Object.assign(this, data);

    if (data.waypoints) {
      this.waypoints = data.waypoints.map((data) => new Waypoint(data));
    }
  }
}
