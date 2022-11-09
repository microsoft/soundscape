// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

import React from 'react';
import { Container, Dropdown, Nav, NavDropdown, Button, Navbar } from 'react-bootstrap';

export default function NavigationBar({ presentingDetail, onActivitiesShow, user }) {
  return (
    <Navbar className="navbar" variant="dark">
      <Container fluid>
        <Navbar.Brand href="/" role="heading" aria-level="1">
          <img
            className="d-inline-block align-text-bottom me-2"
            width="24"
            height="24"
            alt="Brand logo"
            src="/static/media/your_brand_logo.png"
            aria-hidden="true"
          />{' '}
          Authoring Tool
        </Navbar.Brand>

        {presentingDetail && <Navbar.Toggle aria-controls="responsive-navbar-nav" />}

        <Navbar.Collapse id="responsive-navbar-nav" className="justify-content-end">
          <Nav className="me-auto">
            {presentingDetail && (
              <Nav.Item>
                <Button className="me-2" variant="light" onClick={onActivitiesShow} size="sm">
                  My Activities
                </Button>
              </Nav.Item>
            )}
          </Nav>

          {/* The zIndex property fixes an issue were the dropdown is displayed below the map layers control */}
          <Nav style={{ zIndex: 1001 }}>
            <NavDropdown id="nav-dropdown-user" title={user.userName} align="end">
              <Dropdown.Header>Signed in as:</Dropdown.Header>
              <Dropdown.ItemText>{user.userName}</Dropdown.ItemText>
              <Dropdown.ItemText>{user.userEmail}</Dropdown.ItemText>
              <NavDropdown.Divider />
              <NavDropdown.Item href="/.auth/logout">Sign out</NavDropdown.Item>
            </NavDropdown>
          </Nav>
        </Navbar.Collapse>
      </Container>
    </Navbar>
  );
}
