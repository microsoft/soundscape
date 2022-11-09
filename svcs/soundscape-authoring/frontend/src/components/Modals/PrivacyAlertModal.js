// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

import React from 'react';
import Modal from 'react-bootstrap/Modal';
import Button from 'react-bootstrap/Button';

export default class PrivacyAlertModal extends React.Component {
  render() {
    return (
      <Modal show={this.props.show} backdrop="static" centered aria-labelledby="contained-modal-title-vcenter">
        <Modal.Header>
          <Modal.Title>Privacy Agreement</Modal.Title>
        </Modal.Header>
        <Modal.Body>Your Privacy Agreement</Modal.Body>
        <Modal.Footer>
          <Button variant="primary" onClick={this.props.onAccept}>
            Accept
          </Button>
        </Modal.Footer>
      </Modal>
    );
  }
}
