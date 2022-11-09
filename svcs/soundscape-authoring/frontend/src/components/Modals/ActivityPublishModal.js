// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

import React from 'react';
import Modal from 'react-bootstrap/Modal';
import Button from 'react-bootstrap/Button';

import API from '../../api/API';
import { showLoading, dismissLoading } from '../../utils/Toast';
import ErrorAlert from '../Main/ErrorAlert';

export default class ActivityPublishModal extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      error: null,
    };
  }

  publishActivity = () => {
    const toastId = showLoading('Publishing activity...');

    API.publishActivity(this.props.activity.id)
      .then((activity) => {
        dismissLoading(toastId);
        this.props.onPublish(activity);
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
          <Modal.Title>Publish Activity</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <p>{`Are you sure you want to publish the activity named "${this.props.activity?.name}"?`}</p>

          <p>
            Publishing an activity creates or updates the link that can be used with the{' '}
            <a href="https://apps.apple.com/app/idXXXXXXXXXX" target="_blank" rel="noreferrer">
              Your App
            </a>{' '}
            app to start the activity.
            <br />
            <br />
            After publishing, click on the Link button to share or start the activity. Note that it is currently not
            possible to un-publish a published activity.
          </p>

          {this.state.error && <ErrorAlert error={this.state.error} />}
        </Modal.Body>
        <Modal.Footer>
          <Button variant="secondary" onClick={this.props.onCancel}>
            Cancel
          </Button>
          <Button variant="primary" onClick={this.publishActivity}>
            Publish
          </Button>
        </Modal.Footer>
      </Modal>
    );
  }
}
