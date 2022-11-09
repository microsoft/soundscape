// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

import React from 'react';
import Row from 'react-bootstrap/Row';
import { ToastContainer } from 'react-toastify';
import { animateScroll } from 'react-scroll';

import API from './api/API';
import { showError, showLoading, dismissLoading } from './utils/Toast';
import NavigationBar from './components/Main/NavigationBar';
import Footer from './components/Main/Footer';
import ActivityTable from './components/ActivityPrimary/ActivityTable';
import ActivityDetail from './components/ActivitySecondary/ActivityDetail';
import ActivitiesTable from './components/ActivityPrimary/ActivitiesTable';
import ActivityUpdateModal from './components/Modals/ActivityUpdateModal';
import ActivityDeleteModal from './components/Modals/ActivityDeleteModal';
import ActivityDuplicateModal from './components/Modals/ActivityDuplicateModal';
import ActivityPublishModal from './components/Modals/ActivityPublishModal';
import WaypointDeleteModal from './components/Modals/WaypointDeleteModal';
import WaypointUpdateModal from './components/Modals/WaypointUpdateModal';
import ActivityLinkModal from './components/Modals/ActivityLinkModal';
import MapOverlayModal from './components/Modals/MapOverlayModal';
import ActivityImportModal from './components/Modals/ActivityImportModal';
import InvalidWindowSizeAlert from './components/Main/InvalidWindowSizeAlert';
import PrivacyAlertModal from './components/Modals/PrivacyAlertModal';

export default class App extends React.Component {
  static STORAGE_KEYS = Object.freeze({
    DID_ACCEPT_PRIVACY_AGREEMENT: 'did_accept_privacy_agreement',
  });

  constructor(props) {
    super(props);

    this.state = {
      isScreenSizeValid: this.isScreenSizeValid,

      user: {},
      activities: [], // Holds activities metadata excluding waypoints
      selectedActivity: null, // Holds the selected activity including it's waypoints
      selectedWaypoint: null,
      editing: false,
      mapOverlay: null,
      waypointCreateType: null,

      // Activity modals
      showModalPrivacyAlert: this.shouldShowPrivacyAlert,
      showModalMapOverlay: false,
      showModalActivityCreate: false,
      showModalActivityImport: false,
      showModalActivityUpdate: false,
      showModalActivityDelete: false,
      showModalActivityDuplicate: false,
      showModalActivityPublish: false,
      showModalActivityLink: false,

      // Waypoints modals
      showModalWaypointCreate: false,
      showModalWaypointUpdate: false,
      showModalWaypointDelete: false,
    };

    this.bindActions();
  }

  bindActions() {
    // Actions

    this.dismissModal = this.dismissModal.bind(this);
    this.toggleEditing = this.toggleEditing.bind(this);

    // Activities

    this.showActivities = this.showActivities.bind(this);
    this.activitySelected = this.activitySelected.bind(this);
    this.activityCreated = this.activityCreated.bind(this);
    this.activityImported = this.activityImported.bind(this);
    this.activityUpdated = this.activityUpdated.bind(this);
    this.activityDeleted = this.activityDeleted.bind(this);
    this.activityDuplicated = this.activityDuplicated.bind(this);
    this.activityPublished = this.activityPublished.bind(this);

    // Waypoints

    this.waypointSelected = this.waypointSelected.bind(this);
    this.waypointCreateModal = this.waypointCreateModal.bind(this);
    this.waypointCreated = this.waypointCreated.bind(this);
    this.waypointUpdateModal = this.waypointUpdateModal.bind(this);
    this.waypointUpdated = this.waypointUpdated.bind(this);
    this.waypointDeleteModal = this.waypointDeleteModal.bind(this);
    this.waypointDeleted = this.waypointDeleted.bind(this);
  }

  componentDidMount() {
    window.addEventListener('resize', this.handleResize);

    this.authenticate()
      .then((user) => {
        this.setState({
          user,
        });
        this.loadActivities();
      })
      .catch((error) => {
        error.title = 'Error authenticating user';
        showError(error);
      });
  }

  // Actions

  get shouldShowPrivacyAlert() {
    const storedValue = localStorage.getItem(App.STORAGE_KEYS.DID_ACCEPT_PRIVACY_AGREEMENT);
    return !storedValue || storedValue !== 'true';
  }

  get isScreenSizeValid() {
    return window.innerWidth > 1000 && window.innerHeight > 500;
  }

  handleResize = (event) => {
    this.setState({ isScreenSizeValid: this.isScreenSizeValid });
  };

  dismissModal(modalId) {
    this.setState({
      [modalId]: false, // Same as `const state = {}; state[modalId] = false;`
    });
  }

  didAcceptPrivacyAgreement = () => {
    localStorage.setItem(App.STORAGE_KEYS.DID_ACCEPT_PRIVACY_AGREEMENT, 'true');

    this.setState({
      showModalPrivacyAlert: this.shouldShowPrivacyAlert,
    });
  };

  toggleEditing() {
    this.setState({
      editing: !this.state.editing,
      selectedWaypoint: null,
    });
  }

  scrollToBottom() {
    animateScroll.scrollToBottom({ containerId: 'primary' });
  }

  scrollToTop() {
    animateScroll.scrollToTop({ containerId: 'primary' });
  }

  ///////////////////////////////////////////////////////////
  // User
  ///////////////////////////////////////////////////////////

  async authenticate() {
    return API.authenticate();
  }

  ///////////////////////////////////////////////////////////
  // ACTIVITIES
  ///////////////////////////////////////////////////////////

  loadActivities() {
    const toastId = showLoading('Loading activities...');

    API.getActivities()
      .then((activities) => {
        this.setState({
          activities,
          //selectedActivity: activities[0],
        });
      })
      .catch((error) => {
        error.title = 'Error loading activities';
        showError(error);
      })
      .finally(() => {
        dismissLoading(toastId);
      });
  }

  showActivities() {
    this.setState({
      selectedActivity: null,
      selectedWaypoint: null,
      editing: false,
      mapOverlay: null,
    });
  }

  activitySelected(activity) {
    const toastId = showLoading('Loading activity...');

    API.getActivity(activity.id)
      .then((activity) => {
        this.setState({
          selectedActivity: activity,
          editing: false,
        });
      })
      .catch((error) => {
        error.title = 'Error loading activity';
        showError(error);
      })
      .finally(() => {
        dismissLoading(toastId);
      });
  }

  activityCreated(activity) {
    this.setState({
      selectedActivity: activity,
      editing: true,
      showModalActivityCreate: false,
    });

    this.loadActivities();
  }

  activityImported(activity) {
    this.setState({
      selectedActivity: activity,
      editing: false,
      showModalActivityImport: false,
    });

    this.loadActivities();
  }

  activityUpdated(activity) {
    this.setState({
      selectedActivity: activity,
      showModalActivityUpdate: false,
    });

    this.loadActivities();
  }

  activityDeleted(activity) {
    this.setState({
      showModalActivityDelete: false,
    });

    this.showActivities();
    this.loadActivities();
  }

  activityDuplicated(activity) {
    this.setState({
      showModalActivityDuplicate: false,
    });

    this.activitySelected(activity);
    this.loadActivities();

    this.scrollToTop();
  }

  activityPublished(activity) {
    this.setState({
      showModalActivityPublish: false,
    });

    this.activitySelected(activity);
    this.loadActivities();

    this.scrollToTop();
  }

  ///////////////////////////////////////////////////////////
  // WAYPOINTS
  ///////////////////////////////////////////////////////////

  waypointSelected(waypoint) {
    this.setState({
      selectedWaypoint: waypoint,
    });
  }

  waypointCreateModal(type) {
    this.setState({
      waypointCreateType: type,
      showModalWaypointCreate: true,
    });
  }

  waypointCreated(waypoint) {
    this.setState({
      showModalWaypointCreate: false,
    });

    const { selectedActivity } = this.state;

    const toastId = showLoading('Loading activity...');

    API.getActivity(selectedActivity.id)
      .then((activity) => {
        this.setState(
          {
            selectedActivity: activity,
          },
          this.scrollToBottom,
        );
      })
      .catch((error) => {
        error.title = 'Error loading activity';
        showError(error);
      })
      .finally(() => {
        dismissLoading(toastId);
      });
  }

  waypointUpdateModal(waypoint) {
    this.setState({
      selectedWaypoint: waypoint,
      showModalWaypointUpdate: true,
    });
  }

  waypointUpdated(waypoint) {
    this.setState({
      showModalWaypointUpdate: false,
    });

    const { selectedActivity } = this.state;

    const toastId = showLoading('Loading activity...');

    API.getActivity(selectedActivity.id)
      .then((activity) => {
        this.setState({
          selectedActivity: activity,
        });
      })
      .catch((error) => {
        error.title = 'Error loading activity';
        showError(error);
      })
      .finally(() => {
        dismissLoading(toastId);
      });
  }

  waypointMovedUp = (waypoint) => {
    this.waypointMoved(waypoint, 1);
  };

  waypointMovedDown = (waypoint) => {
    this.waypointMoved(waypoint, -1);
  };

  waypointMoved = (waypoint, offset) => {
    const updated = Object.assign({}, waypoint);
    updated.index += offset;

    const toastId = showLoading('Updating waypoint...');

    API.updateWaypoint(updated)
      .then((waypoint) => {
        const { selectedActivity } = this.state;
        API.getActivity(selectedActivity.id)
          .then((activity) => {
            this.setState({
              selectedActivity: activity,
            });
          })
          .catch((error) => {
            error.title = 'Error loading activity';
            showError(error);
          });
      })
      .catch((error) => {
        error.title = 'Error updating waypoint index';
        showError(error);
      })
      .finally(() => {
        dismissLoading(toastId);
      });
  };

  waypointDeleteModal(waypoint) {
    this.setState({
      selectedWaypoint: waypoint,
      showModalWaypointDelete: true,
    });
  }

  waypointDeleted(waypoint) {
    this.setState({
      showModalWaypointDelete: false,
    });

    const { selectedActivity } = this.state;

    const toastId = showLoading('Deleting waypoint...');

    API.getActivity(selectedActivity.id)
      .then((activity) => {
        this.setState({
          selectedWaypoint: null,
          selectedActivity: activity,
        });
      })
      .catch((error) => {
        error.title = 'Error loading activity';
        showError(error);
      })
      .finally(() => {
        dismissLoading(toastId);
      });
  }

  mapOverlayUpdated = (mapOverlay) => {
    this.setState({
      mapOverlay,
      showModalMapOverlay: false,
    });
  };

  render() {
    return (
      <div className="App">
        {this.state.isScreenSizeValid ? (
          <>
            <ToastContainer />

            <NavigationBar
              user={this.state.user}
              onActivitiesShow={this.showActivities}
              presentingDetail={this.state.selectedActivity}
            />

            <main className="main container-fluid">
              <Row className="main-row">
                {/* Primary */}
                {this.state.selectedActivity ? (
                  <ActivityTable
                    activity={this.state.selectedActivity}
                    editing={this.state.editing}
                    onActivityUpdate={() => {
                      this.setState({ showModalActivityUpdate: true });
                    }}
                    onShowActivities={this.showActivities}
                    onWaypointSelected={this.waypointSelected}
                    onWaypointCreate={this.waypointCreateModal}
                    onWaypointDelete={this.waypointDeleteModal}
                    onWaypointUpdate={this.waypointUpdateModal}
                    onWaypointMovedUp={this.waypointMovedUp}
                    onWaypointMovedDown={this.waypointMovedDown}
                  />
                ) : (
                  <ActivitiesTable
                    activities={this.state.activities}
                    onActivitySelected={this.activitySelected}
                    onActivityCreate={() => {
                      this.setState({ showModalActivityCreate: true });
                    }}
                    onActivityImport={() => {
                      this.setState({ showModalActivityImport: true });
                    }}
                  />
                )}

                {/* Secondary */}
                <ActivityDetail
                  activity={this.state.selectedActivity}
                  selectedWaypoint={this.state.selectedWaypoint}
                  editing={this.state.editing}
                  mapOverlay={this.state.mapOverlay}
                  onToggleEditing={this.toggleEditing}
                  onMapOverlay={() => {
                    this.setState({ showModalMapOverlay: true });
                  }}
                  onActivityDelete={() => {
                    this.setState({ showModalActivityDelete: true });
                  }}
                  onActivityDuplicate={() => {
                    this.setState({ showModalActivityDuplicate: true });
                  }}
                  onActivityPublish={() => {
                    this.setState({ showModalActivityPublish: true });
                  }}
                  onActivityLink={() => {
                    this.setState({ showModalActivityLink: true });
                  }}
                  onWaypointCreated={this.waypointCreated}
                  onWaypointUpdated={this.waypointUpdated}
                />
              </Row>
            </main>

            <Footer></Footer>

            {/* Models */}

            <PrivacyAlertModal onAccept={this.didAcceptPrivacyAgreement} show={this.state.showModalPrivacyAlert} />

            <MapOverlayModal
              show={this.state.showModalMapOverlay}
              mapOverlay={this.state.mapOverlay}
              onCancel={this.dismissModal.bind(this, 'showModalMapOverlay')}
              onDone={this.mapOverlayUpdated}
            />

            {/* Activities */}

            <ActivityUpdateModal
              show={this.state.showModalActivityCreate}
              creating={true}
              onCancel={this.dismissModal.bind(this, 'showModalActivityCreate')}
              onDone={this.activityCreated}
            />

            <ActivityImportModal
              show={this.state.showModalActivityImport}
              onCancel={this.dismissModal.bind(this, 'showModalActivityImport')}
              onDone={this.activityImported}
            />

            <ActivityUpdateModal
              show={this.state.showModalActivityUpdate}
              creating={false}
              activity={this.state.selectedActivity}
              onCancel={this.dismissModal.bind(this, 'showModalActivityUpdate')}
              onDone={this.activityUpdated}
            />

            <ActivityDeleteModal
              show={this.state.showModalActivityDelete}
              activity={this.state.selectedActivity}
              onCancel={this.dismissModal.bind(this, 'showModalActivityDelete')}
              onDelete={this.activityDeleted}
            />

            <ActivityDuplicateModal
              show={this.state.showModalActivityDuplicate}
              activity={this.state.selectedActivity}
              onCancel={this.dismissModal.bind(this, 'showModalActivityDuplicate')}
              onDuplicate={this.activityDuplicated}
            />

            <ActivityPublishModal
              show={this.state.showModalActivityPublish}
              activity={this.state.selectedActivity}
              onCancel={this.dismissModal.bind(this, 'showModalActivityPublish')}
              onPublish={this.activityPublished}
            />

            <ActivityLinkModal
              show={this.state.showModalActivityLink}
              activity={this.state.selectedActivity}
              onCancel={this.dismissModal.bind(this, 'showModalActivityLink')}
            />

            {/* Waypoints */}

            <WaypointUpdateModal
              show={this.state.showModalWaypointCreate}
              creating={true}
              waypointType={this.state.waypointCreateType}
              activity={this.state.selectedActivity}
              onCancel={this.dismissModal.bind(this, 'showModalWaypointCreate')}
              onDone={this.waypointCreated}
            />

            <WaypointUpdateModal
              show={this.state.showModalWaypointUpdate}
              creating={false}
              waypoint={this.state.selectedWaypoint}
              activity={this.state.selectedActivity}
              onCancel={this.dismissModal.bind(this, 'showModalWaypointUpdate')}
              onDone={this.waypointUpdated}
            />

            <WaypointDeleteModal
              show={this.state.showModalWaypointDelete}
              waypoint={this.state.selectedWaypoint}
              onCancel={this.dismissModal.bind(this, 'showModalWaypointDelete')}
              onDelete={this.waypointDeleted}
            />
          </>
        ) : (
          <InvalidWindowSizeAlert />
        )}
      </div>
    );
  }
}
