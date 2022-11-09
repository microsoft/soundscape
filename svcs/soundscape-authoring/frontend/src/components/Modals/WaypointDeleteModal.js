// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

import React from 'react';
import Modal from 'react-bootstrap/Modal';
import Button from 'react-bootstrap/Button';

import API from '../../api/API';
import { showLoading, dismissLoading } from '../../utils/Toast';
import ErrorAlert from '../Main/ErrorAlert';

export default class WaypointDeleteModal extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      error: null,
    };
  }

  deleteWaypoint = () => {
    const toastId = showLoading(`Deleting ${this.props.waypoint.typeTitle}...`);

    API.deleteWaypoint(this.props.waypoint.id)
      .then(() => {
        dismissLoading(toastId);
        this.props.onDelete(this.props.waypoint);
      })
      .catch((error) => {
        dismissLoading(toastId);
        this.setState({
          error: error,
        });
      });
  };

  render() {
    return (
      <Modal
        show={this.props.show}
        onHide={this.props.onCancel}
        backdrop="static"
        centered
        aria-labelledby="contained-modal-title-vcenter">
        <Modal.Header closeButton>
          <Modal.Title>{`Delete ${this.props.waypoint?.typeTitle}`}</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          {`Are you sure you want to delete the ${this.props.waypoint?.typeTitle.toLocaleLowerCase()} named "${
            this.props.waypoint?.name
          }"?`}
          {this.state.error && <ErrorAlert error={this.state.error} />}
        </Modal.Body>
        <Modal.Footer>
          <Button variant="secondary" onClick={this.props.onCancel}>
            Cancel
          </Button>
          <Button variant="danger" onClick={this.deleteWaypoint}>
            Delete
          </Button>
        </Modal.Footer>
      </Modal>
    );
  }
}
