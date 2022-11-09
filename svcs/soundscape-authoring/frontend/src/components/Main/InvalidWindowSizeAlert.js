// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

import React from 'react';
import { Alert } from 'react-bootstrap';

export default function InvalidWindowSizeAlert() {
  return (
    <Alert variant="warning">
      <Alert.Heading>Made for bigger screens</Alert.Heading>
      <p>
        Creating activities works best on bigger screens. Please increase the window size or switch to a desktop. The
        minimum supported window size is 100x500 pixels.
      </p>
    </Alert>
  );
}
