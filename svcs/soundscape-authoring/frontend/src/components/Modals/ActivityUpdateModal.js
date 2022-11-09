// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

import React from 'react';
import Modal from 'react-bootstrap/Modal';

import { showLoading, dismissLoading } from '../../utils/Toast';

import ActivityForm from '../Forms/ActivityForm';
import API from '../../api/API';
import ErrorAlert from '../Main/ErrorAlert';

export default class ActivityUpdateModal extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      error: null,
    };

    this.createActivity = this.createActivity.bind(this);
    this.updateActivity = this.updateActivity.bind(this);
  }

  createActivity(activity) {
    const toastId = showLoading('Creating activity...');
    const self = this;

    return new Promise((resolve, reject) => {
      API.createActivity(activity)
        .then((activity) => {
          dismissLoading(toastId);
          self.props.onDone(activity);
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

  updateActivity(activity) {
    const toastId = showLoading('Updating activity...');
    const self = this;

    return new Promise((resolve, reject) => {
      API.updateActivity(activity)
        .then((activity) => {
          dismissLoading(toastId);
          self.props.onDone(activity);
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
    return (
      <Modal
        show={this.props.show}
        onHide={this.props.onCancel}
        backdrop="static"
        centered
        aria-labelledby="contained-modal-title-vcenter">
        <Modal.Header closeButton>
          <Modal.Title>{this.props.creating ? 'Create Activity' : 'Edit Activity'}</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <ActivityForm
            activity={this.props.activity}
            onSubmit={this.props.creating ? this.createActivity : this.updateActivity}
          />
          {this.state.error && <ErrorAlert error={this.state.error} />}
        </Modal.Body>
      </Modal>
    );
  }
}
