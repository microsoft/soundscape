// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

import React from 'react';
import ListGroup from 'react-bootstrap/ListGroup';
import Button from 'react-bootstrap/Button';
import { ArrowDown, ArrowUp, Edit, Trash2 } from 'react-feather';
import Waypoint from '../../data/Waypoint';

function shouldShowWaypointIndex(waypoint) {
  switch (waypoint.type) {
    case Waypoint.TYPE.WAYPOINT:
      return true;
    case Waypoint.TYPE.POI:
      return false;
    default:
      return false;
  }
}

function shouldShowWaypointMoveControls(waypoint) {
  switch (waypoint.type) {
    case Waypoint.TYPE.WAYPOINT:
      return true;
    case Waypoint.TYPE.POI:
      return false;
    default:
      return false;
  }
}

export default function WaypointRow({ waypoint, editing, onSelect, onUpdate, onMoveUp, onMoveDown, onDelete }) {
  return (
    <ListGroup.Item className="py-3 lh-tight" action={!editing} onClick={onSelect.bind(this, waypoint)}>
      <strong className="mb-2">
        {shouldShowWaypointIndex(waypoint) ? `${waypoint.index + 1}. ${waypoint.name}` : waypoint.name}
      </strong>

      {waypoint.description && <p className="mb-1">{waypoint.description}</p>}
      {waypoint.departure_callout && (
        <small>
          {!waypoint.description && <br />}
          <b>{'Departure: '}</b>
          {waypoint.departure_callout}
        </small>
      )}
      {waypoint.departure_callout && waypoint.arrival_callout && <br />}
      {waypoint.arrival_callout && (
        <small>
          {!waypoint.description && !waypoint.departure_callout && <br />}
          <b>{'Arrival: '}</b>
          {waypoint.arrival_callout}
        </small>
      )}

      {editing && (
        <div className="d-flex justify-content-end mt-2" name="editControls">
          <Button
            className="mx-1"
            variant="primary"
            size="sm"
            aria-label="Edit"
            onClick={onUpdate.bind(this, waypoint)}>
            <Edit color="white" size={16} style={{ verticalAlign: 'text-bottom' }} />
          </Button>
          {shouldShowWaypointMoveControls(waypoint) && (
            <>
              <Button
                className="mx-1"
                variant="primary"
                size="sm"
                aria-label="Move Down"
                onClick={onMoveDown ? onMoveDown.bind(this, waypoint) : null}
                disabled={!onMoveDown}>
                <ArrowUp color="white" size={16} style={{ verticalAlign: 'text-bottom' }} />
              </Button>
              <Button
                className="mx-1"
                variant="primary"
                size="sm"
                aria-label="Move Up"
                onClick={onMoveUp ? onMoveUp.bind(this, waypoint) : null}
                disabled={!onMoveUp}>
                <ArrowDown color="white" size={16} style={{ verticalAlign: 'text-bottom' }} />
              </Button>
            </>
          )}
          <Button
            className="mx-1"
            variant="danger"
            size="sm"
            aria-label="Delete"
            onClick={onDelete.bind(this, waypoint)}>
            <Trash2 color="white" size={16} style={{ verticalAlign: 'text-bottom' }} />
          </Button>
        </div>
      )}
    </ListGroup.Item>
  );
}
