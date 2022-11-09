// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

import React from 'react';
import Modal from 'react-bootstrap/Modal';

import API from '../../api/API';
import { showLoading, dismissLoading } from '../../utils/Toast';

import ActivityImportForm from '../Forms/ActivityImportForm';
import ErrorAlert from '../Main/ErrorAlert';

export default class ActivityImportModal extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      error: null,
    };

    this.importActivity = this.importActivity.bind(this);
  }

  importActivity(gpx) {
    const toastId = showLoading('Importing activity...');

    API.importActivity(gpx)
      .then((activity) => {
        dismissLoading(toastId);
        this.props.onDone(activity);
      })
      .catch((error) => {
        dismissLoading(toastId);
        this.setState({
          error: error,
        });
      });
  }

  render() {
    return (
      <Modal
        show={this.props.show}
        onHide={this.props.onCancel}
        backdrop="static"
        centered
        aria-labelledby="contained-modal-title-vcenter">
        <Modal.Header closeButton>
          <Modal.Title>Import Activity</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <ActivityImportForm onSubmit={this.importActivity} />
          {this.state.error && <ErrorAlert error={this.state.error} />}
        </Modal.Body>
      </Modal>
    );
  }
}
