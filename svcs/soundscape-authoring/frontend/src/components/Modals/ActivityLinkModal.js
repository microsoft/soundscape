// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

import React from 'react';
import Modal from 'react-bootstrap/Modal';
import QRCode from 'qrcode.react';
import { Alert } from 'react-bootstrap';

export default class ActivityLinkModal extends React.Component {
  render() {
    // v2: iOS will load activity from production service
    // v3: iOS will load activity from development service
    const link = `https://yourservicesdomain.com/experience?id=${this.props.activity?.id}`;

    return (
      <Modal
        show={this.props.show}
        onHide={this.props.onCancel}
        backdrop="static"
        centered
        aria-labelledby="contained-modal-title-vcenter">
        <Modal.Header closeButton>
          <Modal.Title>Link to Activity</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          {this.props.activity?.unpublished_changes === true && (
            <Alert variant="warning">
              <Alert.Heading>Unpublished Changes Warning</Alert.Heading>
              This activity contains unpublished changes. To update the activity accessed via the public link, select
              Publish prior to sending this link.
            </Alert>
          )}
          <p>
            To start or share this activity, scan the code with your mobile device camera, or copy and paste the link to
            your device browser. Make sure you have{' '}
            <a href="https://apps.apple.com/app/idXXXXXXXXXX" target="_blank" rel="noreferrer">
              Your App
            </a>{' '}
            installed on your device.
          </p>
          <p>
            <b>Note:</b>
            <br></br>
            Before an event, try to send participants the link via e-mail and also take a photo of the QR code on your
            phone. At the day of the event, participants without the link can use their phone to scan the QR code from
            your phone.
          </p>
          <div className="text-center">
            <QRCode value={link} />
          </div>
          <br />
          <a href={link} target="_blank" rel="noreferrer">
            {link}
          </a>
        </Modal.Body>
      </Modal>
    );
  }
}
