// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

import React from 'react';
import Modal from 'react-bootstrap/Modal';

import WaypointForm from '../Forms/WaypointForm';
import API from '../../api/API';
import { showLoading, dismissLoading, showError } from '../../utils/Toast';
import Waypoint from '../../data/Waypoint';
import ErrorAlert from '../Main/ErrorAlert';

export default class WaypointUpdateModal extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      error: null,
    };

    this.createWaypoint = this.createWaypoint.bind(this);
    this.updateWaypoint = this.updateWaypoint.bind(this);
  }

  createWaypoint(waypoint) {
    waypoint.group = this.props.activity.waypointGroupByType(this.props.waypointType).id;
    // The `index` property will be set (if needed) by the server using the latest index + 1

    const toastId = showLoading(`Creating ${Waypoint.typeTitle(this.props.waypointType)}...`);
    const self = this;

    return new Promise((resolve, reject) => {
      API.createWaypoint(waypoint)
        .then((waypoint) => {
          dismissLoading(toastId);
          self.props.onDone(waypoint);
          resolve();
        })
        .catch((error) => {
          dismissLoading(toastId);
          showError(error);
          self.setState({
            error: error,
          });
          reject();
        });
    });
  }

  updateWaypoint(waypoint) {
    const toastId = showLoading(`Updating  ${this.props.waypoint.typeTitle}...`);
    const self = this;

    return new Promise((resolve, reject) => {
      API.updateWaypoint(waypoint)
        .then((waypoint) => {
          dismissLoading(toastId);
          self.props.onDone(waypoint);
          resolve();
        })
        .catch((error) => {
          dismissLoading(toastId);
          self.setState({
            error: error,
          });
          reject();
        });
    });
  }

  render() {
    const typeTitle = this.props.waypoint ? this.props.waypoint.typeTitle : Waypoint.typeTitle(this.props.waypointType);

    return (
      <Modal
        show={this.props.show}
        onHide={this.props.onCancel}
        backdrop="static"
        centered
        aria-labelledby="contained-modal-title-vcenter">
        <Modal.Header closeButton>
          <Modal.Title>
            {this.props.creating ? 'Add' : 'Edit'} {typeTitle}
          </Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <WaypointForm
            waypoint={this.props.waypoint}
            waypointType={this.props.waypointType}
            activity={this.props.activity}
            onSubmit={this.props.creating ? this.createWaypoint : this.updateWaypoint}
          />
          {this.state.error && <ErrorAlert error={this.state.error} />}
        </Modal.Body>
      </Modal>
    );
  }
}
