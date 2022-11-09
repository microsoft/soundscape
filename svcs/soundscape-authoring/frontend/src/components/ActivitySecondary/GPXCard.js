// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

import React from 'react';
import { Card } from 'react-bootstrap';

export default function GPXCard({ gpx }) {
  return (
    <Card className="mb-3">
      <Card.Header>GPX File Details</Card.Header>
      <Card.Body>
        {`Name: ${gpx.metadata.name ?? 'none'}`} <br />
        {`Description: ${gpx.metadata.desc ?? 'none'}`} <br />
        {`Author: ${gpx.metadata.author?.name ?? 'none'}`} <br />
        {`Time: ${gpx.metadata.time ?? 'none'}`} <br />
        {`Waypoints: ${gpx.waypoints.length}`} <br />
        {`Routes: ${gpx.routes.length}`}
        {gpx.routes.length > 0 && <span style={{ color: 'turquoise' }}> (Turquoise)</span>} <br />
        {`Tracks: ${gpx.tracks.length}`}
        {gpx.tracks.length > 0 && <span style={{ color: 'purple' }}> (Purple)</span>} <br />
      </Card.Body>
    </Card>
  );
}
