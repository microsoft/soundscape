// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

import React from 'react';
import {
  MapContainer,
  TileLayer,
  Polyline,
  useMapEvent,
  useMap,
  Popup,
  LayersControl,
  AttributionControl,
  LayerGroup,
} from 'react-leaflet';
import { OverlayTrigger, ToggleButton, ToggleButtonGroup, Tooltip } from 'react-bootstrap';
import { LatLngBounds } from 'leaflet';
import WaypointMarker from './WaypointMarker';
import API from '../../api/API';
import { showError, showLoading, dismissLoading } from '../../utils/Toast';
import { GPXMapOverlaysBounds, GPXMapOverlays } from '../../utils/GPX+MapView';
import { azureMapsTilesetIDs, azureMapUrl, azureMapAttribution } from '../../utils/AzureMapsUtils';
import { GitPullRequest, MapPin } from 'react-feather';
import POIMarker from './POIMarker';
import Waypoint from '../../data/Waypoint';
import Activity from '../../data/Activity';

const DEFAULT_MAP_BOUNDS = [[47.64203029829583, -122.14126189681534]];

const OSM_MAP_TILE_LAYER_DATA = {
  name: 'OSM (Dev)',
  url: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
  attribution:
    '&copy; <a href="https://www.openstreetmap.org/copyright" target="_blank" rel="noreferrer">OpenStreetMap</a>',
};

function shouldShowWaypointCreationControl(activity) {
  switch (activity.type) {
    case Activity.TYPE.ORIENTEERING:
      return false;
    case Activity.TYPE.GUIDED_TOUR:
      return true;
    default:
      return false;
  }
}

function OnMapClick({ onMapClicked }) {
  useMapEvent('click', (event) => {
    // This solves an issue where some map overlay elements,
    // like buttons are passing clicks to the map.
    const className = event.originalEvent.target.className;
    if (typeof className !== 'string') {
      return;
    }
    if (className.includes('leaflet') === false) {
      return;
    }

    onMapClicked(event);
  });
  return null;
}

function CenterMap({ coordinate }) {
  const map = useMap();
  map.setView(coordinate);
  return null;
}

let locatingUser = false;

function LocateUser({ onUserLocationUpdated }) {
  const map = useMap();

  let toastId = undefined;

  useMapEvent('locationfound', (event) => {
    map.stopLocate();
    map.setView(event.latlng);
    dismissLoading(toastId);
    onUserLocationUpdated([event.latlng.lat, event.latlng.lng]);
    locatingUser = false;
  });

  useMapEvent('locationerror', (error) => {
    map.stopLocate();
    dismissLoading(toastId);
    error.title = 'Error locating user';
    showError(error);
    locatingUser = false;
  });

  if (!locatingUser) {
    locatingUser = true;
    toastId = showLoading('Getting location...');
    map.locate();
  }

  return null;
}

function isLatLngValue(latlng) {
  return latlng.lat >= -90 && latlng.lat <= 90 && latlng.lng >= -180 && latlng.lng <= 180;
}

function WaypointCreationControl({ value, onChange }) {
  return (
    <div className="leaflet-bottom leaflet-left">
      <div className="leaflet-control leaflet-bar">
        <OverlayTrigger
          placement="top"
          delay={{ show: 400, hide: 0 }}
          overlay={
            <Tooltip id="waypoints-creation-button-tooltip">
              Select which item will be created when clicking on the map
            </Tooltip>
          }>
          <ToggleButtonGroup size="sm" type="radio" name="Waypoint Creation Control" value={value} onChange={onChange}>
            <ToggleButton id={Waypoint.TYPE.WAYPOINT} value={Waypoint.TYPE.WAYPOINT}>
              <GitPullRequest size={16} style={{ verticalAlign: 'text-bottom' }} /> Waypoints
            </ToggleButton>
            <ToggleButton id={Waypoint.TYPE.POI} value={Waypoint.TYPE.POI}>
              <MapPin size={16} style={{ verticalAlign: 'text-bottom' }} /> Points of Interest
            </ToggleButton>
          </ToggleButtonGroup>
        </OverlayTrigger>
      </div>
    </div>
  );
}

// https://stackoverflow.com/questions/60658422/rending-stateful-components-from-array-grandchild-state-and-parent-state-not-a

export default class MapView extends React.Component {
  static CURSOR_TYPE = Object.freeze({
    DEFAULT: '',
    CROSSHAIR: 'crosshair',
  });

  constructor(props) {
    super(props);

    this.state = {
      map: null,
      creatingWaypoint: false,
      geolocationPermissionGranted: false,
      userLocation: null,
      waypointCreationType: Waypoint.TYPE.WAYPOINT,
    };

    this.setMap = this.setMap.bind(this);
    this.onMapClicked = this.onMapClicked.bind(this);
    this.onWaypointMove = this.onWaypointMove.bind(this);
    this.queryGeolocationPermission = this.queryGeolocationPermission.bind(this);
  }

  componentDidMount() {
    this.queryGeolocationPermission();
  }

  componentDidUpdate(prevProps, prevState) {
    if (this.state.map) {
      this.configureMapCursor();

      if (prevProps.mapOverlay !== this.props.mapOverlay) {
        this.state.map.fitBounds(this.bounds());
      }
    }
  }

  setMap(map) {
    this.setState({
      map: map,
    });

    this.configureMapCursor();
  }

  get cursorType() {
    if (this.state.map) {
      return this.state.map.getContainer().style.cursor;
    }

    return null;
  }

  setCursorType(cursorType) {
    if (this.state.map) {
      this.state.map.getContainer().style.cursor = cursorType;
    }
  }

  configureMapCursor() {
    if (!this.state.map) {
      return;
    }

    if (this.props.editing && this.cursorType !== MapView.CURSOR_TYPE.CROSSHAIR) {
      this.setCursorType(MapView.CURSOR_TYPE.CROSSHAIR);
    } else if (!this.props.editing && this.cursorType !== MapView.CURSOR_TYPE.DEFAULT) {
      this.setCursorType(MapView.CURSOR_TYPE.DEFAULT);
    }
  }

  queryGeolocationPermission() {
    if (!navigator.geolocation) {
      return;
    }

    // Some browsers do not support `permissions`
    // https://developer.mozilla.org/en-US/docs/Web/API/Navigator/permissions
    if (!navigator.permissions) {
      this.setState({
        geolocationPermissionGranted: true,
      });
      return;
    }

    let self = this;
    navigator.permissions.query({ name: 'geolocation' }).then(function (result) {
      if (result.state === 'granted' || result.state === 'prompt') {
        self.setState({
          geolocationPermissionGranted: true,
        });
      }
    });
  }

  // Computed  properties

  bounds() {
    let bounds = null;

    if (this.props.mapOverlay) {
      bounds = GPXMapOverlaysBounds(this.props.mapOverlay);
    } else {
      let coordinates = this.props.activity.waypoints_group.waypoints.map((waypoint) => [
        waypoint.latitude,
        waypoint.longitude,
      ]);

      if (this.props.activity.pois_group) {
        coordinates.concat(
          this.props.activity.pois_group.waypoints.map((waypoint) => [waypoint.latitude, waypoint.longitude]),
        );
      }

      if (coordinates.length > 0) {
        bounds = coordinates;
      } else if (this.state.userLocation) {
        bounds = [this.state.userLocation];
      } else {
        bounds = DEFAULT_MAP_BOUNDS;
      }
    }

    let paddedBounds = new LatLngBounds(bounds).pad(0.1);
    return paddedBounds;
  }

  waypointMarkers() {
    const waypoints = this.props.activity.waypoints_group.waypoints;
    if (waypoints.length === 0) {
      return null;
    }

    return waypoints.map((waypoint) => (
      <WaypointMarker
        key={waypoint.id}
        waypoint={waypoint}
        editing={this.props.editing}
        onWaypointMove={this.onWaypointMove}
      />
    ));
  }

  waypointMarkersPolyline() {
    const coordinates = this.props.activity.waypoints_group.waypoints.map((waypoint) => [
      waypoint.latitude,
      waypoint.longitude,
    ]);

    if (coordinates.length === 0) {
      return null;
    }

    return (
      <Polyline key="markers-polyline" pathOptions={{ color: 'blue' }} positions={coordinates}>
        <Tooltip>Waypoints Route</Tooltip>
        <Popup>Waypoints Route</Popup>
      </Polyline>
    );
  }

  poiMarkers() {
    if (!this.props.activity.pois_group) {
      return null;
    }

    const waypoints = this.props.activity.pois_group.waypoints;
    if (waypoints.length === 0) {
      return null;
    }

    return waypoints.map((waypoint) => (
      <POIMarker
        key={waypoint.id}
        waypoint={waypoint}
        editing={this.props.editing}
        onWaypointMove={this.onWaypointMove}
      />
    ));
  }
  // Actions

  onWaypointCreationTypeChanged = (value) => {
    this.setState({
      waypointCreationType: value,
    });
  };

  onUserLocationUpdated = (userLocation) => {
    this.setState({
      userLocation: userLocation,
    });
  };

  onMapClicked = (event) => {
    if (!this.props.editing || !isLatLngValue(event.latlng) || this.state.creatingWaypoint) {
      return;
    }

    this.setState({
      creatingWaypoint: true,
    });

    const waypointGroup = this.props.activity.waypointGroupByType(this.state.waypointCreationType);
    const name = Waypoint.typeTitle(this.state.waypointCreationType);

    const waypoint = {
      group: waypointGroup.id,
      name: name,
      description: null,
      latitude: event.latlng.lat.toFixed(6),
      longitude: event.latlng.lng.toFixed(6),
      // The `index` property will be set (if needed) by the server using the latest index + 1
    };

    const toastId = showLoading(`Creating ${name}...`);

    API.createWaypoint(waypoint)
      .then((waypoint) => {
        this.props.onWaypointCreated(waypoint);
        dismissLoading(toastId);
      })
      .catch((error) => {
        dismissLoading(toastId);
        error.title = `Error creating ${name}`;
        showError(error);
      })
      .finally(() => {
        this.setState({
          creatingWaypoint: false,
        });
      });
  };

  onWaypointMove(waypointId, coordinate) {
    let waypoint = this.props.activity.waypoints_group.waypoints.find((waypoint) => waypoint.id === waypointId);
    if (!waypoint && this.props.activity.pois_group) {
      waypoint = this.props.activity.pois_group.waypoints.find((waypoint) => waypoint.id === waypointId);
    }

    const waypoint_ = Object.assign({}, waypoint);

    waypoint_.latitude = coordinate.lat.toFixed(6);
    waypoint_.longitude = coordinate.lng.toFixed(6);

    const toastId = showLoading('Updating waypoint...');

    API.updateWaypoint(waypoint_)
      .then((waypoint) => {
        dismissLoading(toastId);
        this.props.onWaypointUpdated(waypoint);
      })
      .catch((error) => {
        dismissLoading(toastId);
        error.title = 'Error updating waypoint';
        showError(error);
      });
  }

  render() {
    let shouldLocateUser =
      this.state.geolocationPermissionGranted &&
      this.props.activity.waypoints_group.waypoints.length === 0 &&
      !this.state.userLocation;

    let selectedWaypointCoordinate = this.props.selectedWaypoint
      ? [this.props.selectedWaypoint.latitude, this.props.selectedWaypoint.longitude]
      : null;

    return (
      <MapContainer bounds={this.bounds()} zoom={19} worldCopyJump={true} ref={this.setMap} attributionControl={false}>
        <LayersControl position="topright">
          {/* Default layers */}
          {azureMapsTilesetIDs.map((tilesetID) => (
            <LayersControl.BaseLayer key={tilesetID.id} name={tilesetID.name} checked={tilesetID.default}>
              <TileLayer url={azureMapUrl(tilesetID.id)} attribution={azureMapAttribution} />
            </LayersControl.BaseLayer>
          ))}

          {/* Group layers */}
          <LayersControl.BaseLayer name="Satellite & Roads">
            <LayerGroup>
              <TileLayer url={azureMapUrl('microsoft.imagery')} attribution={azureMapAttribution} />
              <TileLayer url={azureMapUrl('microsoft.base.hybrid.road')} attribution={azureMapAttribution} />
            </LayerGroup>
          </LayersControl.BaseLayer>

          {/* DEV layers */}
          {process.env.NODE_ENV === 'development' && (
            <LayersControl.BaseLayer name={OSM_MAP_TILE_LAYER_DATA.name}>
              <TileLayer url={OSM_MAP_TILE_LAYER_DATA.url} attribution={OSM_MAP_TILE_LAYER_DATA.attribution} />
            </LayersControl.BaseLayer>
          )}
          <LayersControl.Overlay checked name="Waypoints">
            <LayerGroup>
              {this.waypointMarkersPolyline()}
              {this.waypointMarkers()}
            </LayerGroup>
          </LayersControl.Overlay>
          <LayersControl.Overlay checked name="Points of Interest">
            <LayerGroup>{this.poiMarkers()}</LayerGroup>
          </LayersControl.Overlay>
        </LayersControl>

        {this.props.editing && shouldShowWaypointCreationControl(this.props.activity) && (
          <WaypointCreationControl
            value={this.state.waypointCreationType}
            onChange={this.onWaypointCreationTypeChanged}
          />
        )}

        {/* Remove the attribution prefix */}
        <AttributionControl position="bottomright" prefix="" />

        {/* Map controls and location */}
        <OnMapClick onMapClicked={this.onMapClicked} />
        {shouldLocateUser && <LocateUser onUserLocationUpdated={this.onUserLocationUpdated} />}
        {selectedWaypointCoordinate && <CenterMap coordinate={selectedWaypointCoordinate} />}

        {/* Map Annotations */}
        {GPXMapOverlays(this.props.mapOverlay)}
      </MapContainer>
    );
  }
}
