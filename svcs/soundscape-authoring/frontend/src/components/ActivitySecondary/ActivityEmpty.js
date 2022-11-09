// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

import React from 'react';
import { Info } from 'react-feather';

export default function ActivityEmpty() {
  return (
    <div
      className="d-flex align-items-center justify-content-center flex-column p-4"
      style={{ height: '100%', backgroundColor: 'white' }}>
      <Info size={32} style={{ verticalAlign: 'text-bottom' }} />
      {/* <span className="fs-5 fw-bold me-2">No Activity Selected</span> */}
      <h2 className="fs-5 mt-2">Create or select an activity from the list.</h2>
    </div>
  );
}
