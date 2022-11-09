// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

import React from 'react';
import { Alert } from 'react-bootstrap';
import { errorContent } from '../../utils/Toast';

export default function ErrorAlert({ error }) {
  const errorTitle = error?.message ?? 'Error';
  const errorMessage = errorContent(error);

  return (
    <Alert className="mt-3" variant="danger">
      {errorTitle}
      {errorTitle !== errorMessage && process.env.NODE_ENV === 'development' && (
        <>
          <br />
          {errorMessage}
        </>
      )}
    </Alert>
  );
}
