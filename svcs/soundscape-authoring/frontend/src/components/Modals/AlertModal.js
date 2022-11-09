// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

import React from 'react';
import Modal from 'react-bootstrap/Modal';
import Button from 'react-bootstrap/Button';

export default class AlertModal extends React.Component {
  render() {
    return (
      <Modal
        show={true}
        onHide={this.props.onClickDismiss}
        backdrop="static"
        centered
        aria-labelledby="contained-modal-title-vcenter">
        <Modal.Header closeButton>
          <Modal.Title>{this.props.title}</Modal.Title>
        </Modal.Header>
        <Modal.Body>{this.props.message}</Modal.Body>
        <Modal.Footer>
          <Button variant="secondary" onClick={this.props.onClickDismiss}>
            {this.props.dismissButtonTitle}
          </Button>
          {this.props.actionButtonTitle && (
            <Button variant={this.props.actionButtonVariant} onClick={this.props.onClickAction}>
              {this.props.actionButtonTitle}
            </Button>
          )}
        </Modal.Footer>
      </Modal>
    );
  }
}

AlertModal.defaultProps = {
  dismissButtonTitle: 'Dismiss',
  actionButtonVariant: 'primary',
};
