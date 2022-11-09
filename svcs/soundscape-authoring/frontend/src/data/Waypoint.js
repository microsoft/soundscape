// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

import WaypointMedia from './WaypointMedia';

export default class Waypoint {
  static TYPE = Object.freeze({
    WAYPOINT: 'ordered',
    POI: 'unordered',
  });

  static typeTitle(type) {
    switch (type) {
      case Waypoint.TYPE.WAYPOINT:
        return 'Waypoint';
      case Waypoint.TYPE.POI:
        return 'Point of Interest';
      default:
        return null;
    }
  }

  constructor(data) {
    Object.assign(this, data);

    if (data.images) {
      this.images = data.images.map((data) => new WaypointMedia(data));
    }

    if (data.audio_clips) {
      this.audio_clips = data.audio_clips.map((data) => new WaypointMedia(data));
    }
  }

  get typeTitle() {
    return Waypoint.typeTitle(this.type);
  }
}
