// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

import React from 'react';
import Modal from 'react-bootstrap/Modal';
import Button from 'react-bootstrap/Button';

import API from '../../api/API';
import { showLoading, dismissLoading } from '../../utils/Toast';
import ErrorAlert from '../Main/ErrorAlert';

export default class ActivityDeleteModal extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      error: null,
    };
  }

  deleteActivity = () => {
    const toastId = showLoading('Deleting activity...');

    API.deleteActivity(this.props.activity.id)
      .then(() => {
        dismissLoading(toastId);
        this.props.onDelete(this.props.activity);
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
          <Modal.Title>Delete Activity</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          {`Are you sure you want to delete the activity named "${this.props.activity?.name}"?`}
          {this.state.error && <ErrorAlert error={this.state.error} />}
        </Modal.Body>
        <Modal.Footer>
          <Button variant="secondary" onClick={this.props.onCancel}>
            Cancel
          </Button>
          <Button variant="danger" onClick={this.deleteActivity}>
            Delete
          </Button>
        </Modal.Footer>
      </Modal>
    );
  }
}
