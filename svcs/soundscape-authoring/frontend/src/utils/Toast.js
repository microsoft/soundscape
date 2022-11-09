// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

import React from 'react';
import { toast } from 'react-toastify';

const ErrorToast = ({ title, subtitle }) => (
  <div>
    <h5>{title ? title : 'An error has occurred'}</h5>
    <p>{subtitle ? subtitle : ''}</p>
  </div>
);

const errorToastOptions = {
  position: toast.POSITION.BOTTOM_RIGHT,
  draggable: true,
  progress: undefined,
  pauseOnHover: true,
  newestOnTop: false,

  autoClose: 5000,
  hideProgressBar: false,
  closeOnClick: true,
};

const loadingToastOptions = {
  position: toast.POSITION.BOTTOM_RIGHT,
  draggable: true,
  progress: undefined,
  pauseOnHover: true,
  newestOnTop: false,

  autoClose: false,
  hideProgressBar: true,
  closeOnClick: false,
};

export const errorContent = (error) => {
  let content;
  if (error.response?.headers && error.response.headers['content-type'] !== 'text/html') {
    content = error.response.data;
  } else if (error.message) {
    content = error.message;
  } else {
    content = error;
  }

  if (typeof content !== 'string') {
    content = JSON.stringify(content);
  }

  return content;
};

export const showError = (error) => {
  return toast.error(<ErrorToast title={error.title} subtitle={errorContent(error)} />, errorToastOptions);
};

export const showLoading = (text) => {
  return toast.info(text, loadingToastOptions);
};

export const dismissLoading = (toastId) => {
  return toast.dismiss(toastId);
};
