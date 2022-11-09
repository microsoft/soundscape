// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

import React from 'react';
import Row from 'react-bootstrap/Row';

import ActivityDetailHeader from './ActivityDetailHeader';
import EmptyActivity from './ActivityEmpty';
import MapView from './MapView';

export default class ActivityDetail extends React.Component {
  render() {
    return (
      <div className="col-7 col-xs-1 col-sm-6 col-md-8 col-lg-9 d-flex flex-column h-100" id="secondary">
        {this.props.activity ? (
          <>
            <ActivityDetailHeader
              activity={this.props.activity}
              editing={this.props.editing}
              mapOverlay={this.props.mapOverlay}
              onToggleEditing={this.props.onToggleEditing}
              onActivityDelete={this.props.onActivityDelete}
              onActivityDuplicate={this.props.onActivityDuplicate}
              onActivityPublish={this.props.onActivityPublish}
              onActivityLink={this.props.onActivityLink}
              onMapOverlay={this.props.onMapOverlay}
            />
            <Row className="flex-grow-1">
              <MapView
                activity={this.props.activity}
                selectedWaypoint={this.props.selectedWaypoint}
                editing={this.props.editing}
                mapOverlay={this.props.mapOverlay}
                onWaypointCreated={this.props.onWaypointCreated}
                onWaypointUpdated={this.props.onWaypointUpdated}
              />
            </Row>
          </>
        ) : (
          <EmptyActivity />
        )}
      </div>
    );
  }
}
