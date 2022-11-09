// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

// More info: https://docs.microsoft.com/en-us/rest/api/maps/render-v2/get-map-tile

export const azureMapAttribution =
  '&copy; <a href="https://azure.microsoft.com/en-us/services/azure-maps/" target="_blank" rel="noreferrer">Azure Maps</a>';

export const azureMapsTilesetIDs = [
  { name: 'Default', id: 'microsoft.base.road', default: true },
  { name: 'Dark', id: 'microsoft.base.darkgrey' },
  { name: 'Satellite', id: 'microsoft.imagery' },
];

let defaultMapOptions = {
  tilesetId: 'microsoft.base.road',
  tileSize: '256',
  language: 'en-US',
  view: 'Auto',
};

export const azureMapUrl = (tilesetId = defaultMapOptions.tilesetId) => {
  return `/map/?tileset_id=${tilesetId}&tile_size=${defaultMapOptions.tileSize}&language=${defaultMapOptions.language}&view=${defaultMapOptions.view}&zoom={z}&x={x}&y={y}`;
};
