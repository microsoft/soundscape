// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

import React from 'react';
import ListGroup from 'react-bootstrap/ListGroup';

export default function TableRow({ onClick, title, subtitle }) {
  return (
    <ListGroup.Item className="py-3 lh-tight" onClick={onClick} action={onClick ? true : false}>
      <strong className="mb-1">{title}</strong>
      <p className="mb-1">{subtitle ? subtitle : '-'}</p>
    </ListGroup.Item>
  );
}
