// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

import React from 'react';

export default function TableHeader({ title, subheaderView }) {
  return (
    <div className="d-flex align-items-center flex-shrink-0 p-3 link-dark text-decoration-none border-bottom">
      <div className="d-flex w-100 align-items-center justify-content-between">
        <h1 className="fs-5 fw-bold me-2 mb-0">{title}</h1>
        {subheaderView && subheaderView}
      </div>
    </div>
  );
}
