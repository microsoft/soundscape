// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

import React from 'react';
import { Plus, MapPin, Edit } from 'react-feather';
import ListGroup from 'react-bootstrap/ListGroup';
import Button from 'react-bootstrap/Button';

import TableRow from '../Table/TableRow';
import WaypointRow from './WaypointRow';
import TableHeader from '../Table/TableHeader';
import TableRowEmpty from '../Table/TableRowEmpty';
import TableRowImage from '../Table/TableRowImage';
import Waypoint from '../../data/Waypoint';
import Activity from '../../data/Activity';

function shouldShowPOIsSection(activity) {
  switch (activity.type) {
    case Activity.TYPE.ORIENTEERING:
      return false;
    case Activity.TYPE.GUIDED_TOUR:
      return true;
    default:
      return false;
  }
}

function WaypointRowEmpty() {
  const icon = <MapPin size={16} style={{ verticalAlign: 'text-bottom' }} />;
  return <TableRowEmpty title="No Waypoints" subtitle="Press Edit and tap on the map to add a waypoint." icon={icon} />;
}

function POIRowEmpty() {
  const icon = <MapPin size={16} style={{ verticalAlign: 'text-bottom' }} />;
  return (
    <TableRowEmpty
      title="No Points of Interest"
      subtitle="Press Edit and tap on the map to add a point of interest."
      icon={icon}
    />
  );
}

function EditMetadataButton({ onClick }) {
  return (
    <Button size="sm" variant="primary" aria-label="Edit Activity Information" onClick={onClick}>
      <Edit className="me-1" size={16} style={{ verticalAlign: 'text-bottom' }} />
      Edit
    </Button>
  );
}

function AddWaypointButton({ onClick }) {
  return (
    <Button size="sm" variant="primary" onClick={onClick}>
      <Plus className="me-1" size={16} style={{ verticalAlign: 'text-bottom' }} />
      Add
    </Button>
  );
}

export default function ActivityInfoTable(props) {
  const waypoints = props.activity.waypoints_group.waypoints;
  const pois = props.activity.pois_group?.waypoints ?? [];

  let startDate = props.activity.start ? new Date(props.activity.start) : null;
  if (startDate) {
    startDate = startDate.toUTCString();
  }
  let endDate = props.activity.end ? new Date(props.activity.end) : null;
  if (endDate) {
    endDate = endDate.toUTCString();
  }

  const onClick = props.editing ? props.onActivityUpdate : null;

  const subheaderView = props.editing ? <EditMetadataButton onClick={props.onActivityUpdate} /> : null;

  return (
    <div className="col-5 col-xs-1 col-sm-6 col-md-4 col-lg-3 p-0 border-end" id="primary">
      {/* Metadata */}
      <section className="d-flex flex-column" aria-label="Activity Information">
        <TableHeader title={props.activity.name} subheaderView={subheaderView} />

        <ListGroup className="border-bottom" variant="flush">
          {props.activity.image_url && (
            <TableRowImage image={props.activity.image_url} alt={props.activity.image_alt} onClick={onClick} />
          )}
          <TableRow title="Name" subtitle={props.activity.name} onClick={onClick} />
          <TableRow title="Description" subtitle={props.activity.description} onClick={onClick} />
          <TableRow title="Author / Organization" subtitle={props.activity.author_name} onClick={onClick} />
          <TableRow title="Type" subtitle={props.activity.type} onClick={onClick} />
          <TableRow title="Start Date" subtitle={startDate} onClick={onClick} />
          <TableRow title="End Date" subtitle={endDate} onClick={onClick} />
          <TableRow title="Expires" subtitle={props.activity.expires ? 'Yes' : 'No'} onClick={onClick} />
        </ListGroup>
      </section>

      {/* Waypoints */}
      <section className="d-flex flex-column" aria-label="Waypoints">
        <TableHeader
          title="Waypoints"
          subheaderView={
            props.editing ? (
              <AddWaypointButton onClick={props.onWaypointCreate.bind(this, Waypoint.TYPE.WAYPOINT)} />
            ) : null
          }
        />

        <ListGroup className="border-bottom" variant="flush">
          {waypoints && waypoints.length > 0 ? (
            waypoints.map((waypoint, index) => (
              <WaypointRow
                key={waypoint.id}
                waypoint={waypoint}
                editing={props.editing}
                onSelect={props.onWaypointSelected}
                onDelete={props.onWaypointDelete}
                onUpdate={props.onWaypointUpdate}
                onMoveDown={index !== 0 ? props.onWaypointMovedDown : null}
                onMoveUp={index !== waypoints.length - 1 ? props.onWaypointMovedUp : null}
              />
            ))
          ) : (
            <WaypointRowEmpty />
          )}
        </ListGroup>
      </section>

      {/* POIs */}
      {shouldShowPOIsSection(props.activity) && (
        <section className="d-flex flex-column" aria-label="Points of Interest">
          <TableHeader
            title="Points of Interest"
            subheaderView={
              props.editing ? (
                <AddWaypointButton onClick={props.onWaypointCreate.bind(this, Waypoint.TYPE.POI)} />
              ) : null
            }
          />

          <ListGroup className="border-bottom" variant="flush">
            {pois && pois.length > 0 ? (
              pois.map((waypoint, index) => (
                <WaypointRow
                  key={waypoint.id}
                  waypoint={waypoint}
                  editing={props.editing}
                  onSelect={props.onWaypointSelected}
                  onDelete={props.onWaypointDelete}
                  onUpdate={props.onWaypointUpdate}
                  onMoveDown={index !== 0 ? props.onWaypointMovedDown : null}
                  onMoveUp={index !== waypoints.length - 1 ? props.onWaypointMovedUp : null}
                />
              ))
            ) : (
              <POIRowEmpty />
            )}
          </ListGroup>
        </section>
      )}
    </div>
  );
}
