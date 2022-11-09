// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

import React from 'react';
import Row from 'react-bootstrap/Row';
import ButtonToolbar from 'react-bootstrap/ButtonToolbar';
import ButtonGroup from 'react-bootstrap/ButtonGroup';
import Button from 'react-bootstrap/Button';
import { CheckCircle, ExternalLink, Copy, Trash, Edit, Save, Link, Map } from 'react-feather';

export default function ActivityDetailHeader(props) {
  return (
    <Row style={{ backgroundColor: 'rgb(249, 244, 244)' }}>
      <div className="d-flex justify-content-between flex-wrap flex-md-nowrap align-items-center p-3 border-bottom">
        <div>
          {/* <span className="fs-5 fw-bold me-2">Activity</span> */}
          {/* <small>Toggle Edit and tap on the map to add a waypoint</small> */}
        </div>

        <ButtonToolbar aria-label="Activity Actions">
          <ButtonGroup>
            <Button
              variant={props.mapOverlay ? 'secondary' : 'outline-secondary'}
              aria-label="Overlay"
              onClick={props.onMapOverlay}>
              <Map className="me-1" size={16} style={{ verticalAlign: '-10%' }} />
              Overlay
            </Button>
          </ButtonGroup>
          <ButtonGroup className="me-2 ms-2 mb-2 mb-lg-0">
            <Button
              variant="outline-secondary"
              aria-label="Activity Link"
              onClick={props.onActivityLink}
              disabled={!props.activity.can_link}>
              <span data-feather="external-link"></span>
              <Link className="me-1" size={16} style={{ verticalAlign: '-10%' }} />
              Link
            </Button>
            <Button
              variant="outline-secondary"
              aria-label="Publish Activity"
              onClick={props.onActivityPublish}
              disabled={!props.activity.unpublished_changes}>
              <CheckCircle className="me-1" size={16} style={{ verticalAlign: '-10%' }} />
              Publish
            </Button>
            <Button
              variant="outline-secondary"
              aria-label="Export"
              href={`/api/v1/activities/${props.activity.id}/export_gpx/`}>
              <span data-feather="external-link"></span>
              <ExternalLink className="me-1" size={16} style={{ verticalAlign: '-10%' }} />
              Export
            </Button>
            <Button variant="outline-secondary" aria-label="Duplicate Activity" onClick={props.onActivityDuplicate}>
              <Copy className="me-1" size={16} style={{ verticalAlign: '-10%' }} />
              Duplicate
            </Button>
            <Button variant="outline-secondary" aria-label="Delete Activity" onClick={props.onActivityDelete}>
              <Trash className="me-1" size={16} style={{ verticalAlign: '-10%' }} />
              Delete
            </Button>
          </ButtonGroup>

          <ButtonGroup>
            {props.editing ? (
              <Button variant="success" aria-label="Finish Editing" onClick={props.onToggleEditing}>
                <Save className="me-1" size={16} style={{ verticalAlign: '-10%' }} />
                Finish
              </Button>
            ) : (
              <Button variant="primary" aria-label="Edit Activity" onClick={props.onToggleEditing}>
                <Edit className="me-1" size={16} style={{ verticalAlign: '-10%' }} />
                Edit
              </Button>
            )}
          </ButtonGroup>
        </ButtonToolbar>
      </div>
    </Row>
  );
}
