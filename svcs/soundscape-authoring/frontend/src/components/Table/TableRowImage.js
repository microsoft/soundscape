// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

import React from 'react';
import { Image } from 'react-bootstrap';
import ListGroup from 'react-bootstrap/ListGroup';

export default function TableRowImage({ onClick, image, alt }) {
  return (
    <ListGroup.Item className="py-3 lh-tight" onClick={onClick} action={onClick ? true : false}>
      <Image src={image} alt={alt} width="100%" height="160px" style={{ objectFit: 'cover' }} />
    </ListGroup.Item>
  );
}
