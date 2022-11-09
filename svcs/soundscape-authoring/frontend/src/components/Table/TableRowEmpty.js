// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

import React from 'react';
import ListGroup from 'react-bootstrap/ListGroup';

export default function TableRowEmpty({ onClick, icon, title, subtitle }) {
  return (
    <ListGroup.Item
      className="py-3 lh-tight text-center"
      onClick={onClick}
      action={onClick ? true : false}
      aria-current="true">
      <div>{icon && icon}</div>
      {title && <strong className="mb-1">{title}</strong>}
      {subtitle && <p className="mb-1">{subtitle}</p>}
    </ListGroup.Item>
  );
}
