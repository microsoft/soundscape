// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

import React from 'react';
import Modal from 'react-bootstrap/Modal';

import MapOverlayForm from '../Forms/MapOverlayForm';

export default class MapOverlayModal extends React.Component {
  updateOverlay = (overlay) => {
    this.props.onDone(overlay);
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
          <Modal.Title>Map Overlay</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <MapOverlayForm mapOverlay={this.props.mapOverlay} onSubmit={this.updateOverlay} />
        </Modal.Body>
      </Modal>
    );
  }
}
