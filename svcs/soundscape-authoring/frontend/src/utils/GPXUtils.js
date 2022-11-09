// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

import gpxParser from 'gpxparser';

export const fileToGPX = async (gpxFile) => {
  if (!gpxFile || !(gpxFile instanceof File)) {
    return Promise.reject('Invalid GPX file');
  }

  return new Promise((resolve, reject) => {
    gpxFile.text().then((text) => {
      const gpx = new gpxParser();
      gpx.parse(text);
      if (gpx) {
        resolve(gpx);
      } else {
        reject('Invalid GPX file');
      }
    });
  });
};

export const isGPXFileValid = async (gpxFile) => {
  if (!gpxFile || !(gpxFile instanceof File)) {
    return false;
  }

  const gpx = await fileToGPX(gpxFile);
  return isGPXObjectValid(gpx);
};

export const isGPXObjectValid = (gpx) => {
  if (gpx instanceof gpxParser === false) {
    return false;
  }
  return gpx.waypoints.length > 0 || gpx.tracks.length > 0 || gpx.routes.length > 0;
};
