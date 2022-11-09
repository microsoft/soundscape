// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

import React from 'react';
import { Marker, Popup, Tooltip } from 'react-leaflet';
import { Icon } from 'leaflet';

const mapPinIcon = new Icon({
  iconUrl: 'static/media/map-pin-waypoint.png',
  iconSize: [42, 42],
  iconAnchor: [21, 37],
});

export default function WaypointMarker({ waypoint, editing, onWaypointMove }) {
  const title = `${waypoint.index + 1}. ${waypoint.name}`;
  return (
    <Marker
      position={[waypoint.latitude, waypoint.longitude]}
      title={title}
      icon={mapPinIcon}
      draggable={editing}
      waypoint={waypoint}
      eventHandlers={{
        dragend: (event) => {
          // We pass the waypoint ID and not the object itself because for some reason
          // it is passing the object the map loaded the first time.
          // If the waypoint was edited, such as a change in name, it will still
          // return the original object.
          onWaypointMove(event.target.options.waypoint.id, event.target._latlng);
        },
      }}>
      <Tooltip permanent>{`${waypoint.index + 1}`}</Tooltip>
      <Popup>
        <strong>{`${waypoint.index + 1}. ${waypoint.name}`}</strong>
        <br />
        {waypoint.description && (
          <>
            {' '}
            <br />
            {waypoint.description}
            <br />
          </>
        )}
        <br />
        {waypoint.latitude}, {waypoint.longitude}
        {waypoint.departure_callout && (
          <>
            {' '}
            <br />
            <br />
            {`Departure Callout: ${waypoint.departure_callout}`}
          </>
        )}
        {waypoint.arrival_callout && (
          <>
            {' '}
            <br />
            {`Arrival Callout: ${waypoint.arrival_callout}`}
          </>
        )}
      </Popup>
    </Marker>
  );
}
