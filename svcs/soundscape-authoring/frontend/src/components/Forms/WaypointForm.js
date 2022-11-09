// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

import React from 'react';
import { Form, Button, Row, Col, Container, Alert, OverlayTrigger, Tooltip } from 'react-bootstrap';
import { Formik } from 'formik';
import * as yup from 'yup';
import Dropzone from 'react-dropzone';
import ImageThumb from './ImageThumb';
import AudioClip from './AudioClip';
import Activity from '../../data/Activity';
import Waypoint from '../../data/Waypoint';
import API from '../../api/API';
import { dismissLoading, showError, showLoading } from '../../utils/Toast';

const MAX_MEDIA_FILES = 5;

function maxDigits(num, max) {
  if (typeof num !== 'number') {
    return false;
  }
  return num.toString().replace('.', '').replace('-', '').length <= max;
}

const waypointSchema = yup.object().shape({
  name: yup.string().trim().required('Name is a required field'),
  latitude: yup
    .number()
    .required('Latitude is a required field')
    .min(-90)
    .max(90)
    .test('length', 'Ensure that there are no more than 9 digits in total', (num) => maxDigits(num, 9)),
  longitude: yup
    .number()
    .required('Longitude is a required field')
    .min(-180)
    .max(180)
    .test('length', 'Ensure that there are no more than 9 digits in total', (num) => maxDigits(num, 9)),
  description: yup.string().trim(),

  images: yup.array().of(yup.object()),
  image_files: yup.array().of(yup.mixed()),
  image_file_alts: yup.array().of(yup.string()),

  audio_clips: yup.array().of(yup.object()),
  audio_clip_files: yup.array().of(yup.mixed()),
  audio_clip_file_texts: yup.array().of(yup.string()),

  departure_callout: yup.string().trim(),
  arrival_callout: yup.string().trim(),
});

const dropzoneStyle = {
  width: '100%',
  height: 'auto',
  borderWidth: 2,
  borderColor: 'rgb(102, 102, 102)',
  borderStyle: 'dashed',
  borderRadius: 5,
};

function shouldShowExtraWaypointInputs(waypointType) {
  switch (waypointType) {
    case Waypoint.TYPE.WAYPOINT:
      return true;
    case Waypoint.TYPE.POI:
      return false;
    default:
      return false;
  }
}

function shouldShowMediaInputs(activity) {
  switch (activity.type) {
    case Activity.TYPE.ORIENTEERING:
      return false;
    case Activity.TYPE.GUIDED_TOUR:
      return true;
    default:
      return false;
  }
}

export default class WaypointForm extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      waypointType: props.waypointType ?? props.waypoint.type,
    };

    this.ImageDropzoneContent = this.ImageDropzoneContent.bind(this);
    this.AudioDropzoneContent = this.AudioDropzoneContent.bind(this);
  }

  onSubmit = (values, { setSubmitting }) => {
    let waypoint = Object.assign({}, values);

    if (waypoint.image_files) {
      waypoint.images = waypoint.image_files;
      delete waypoint.image_files;
    }

    if (waypoint.image_file_alts) {
      waypoint.image_alts = waypoint.image_file_alts;
      delete waypoint.image_file_alts;
    }

    if (waypoint.audio_clip_files) {
      waypoint.audio_clips = waypoint.audio_clip_files;
      delete waypoint.audio_clip_files;
    }

    if (waypoint.audio_clip_file_texts) {
      waypoint.audio_clip_texts = waypoint.audio_clip_file_texts;
      delete waypoint.audio_clip_file_texts;
    }

    this.props.onSubmit(waypoint).finally(() => {
      setSubmitting(false);
    });
  };

  shouldDisableImageInput(values) {
    const images = values.images.length + values.image_files.length;
    return images >= MAX_MEDIA_FILES;
  }

  shouldDisableAudioInput(values) {
    const images = values.audio_clips.length + values.audio_clip_files.length;
    return images >= MAX_MEDIA_FILES;
  }

  ImageDropzoneContent({ isDragActive, isDragReject, values }) {
    if (this.shouldDisableImageInput(values)) {
      return (
        <Alert className="mt-3" variant="secondary">
          Max number of files reached
        </Alert>
      );
    } else if (!isDragActive) {
      return <p className="mt-3">Drag or click to select files</p>;
    } else if (isDragActive && !isDragReject) {
      return <p className="mt-3">Drop files</p>;
    } else if (isDragActive && isDragReject) {
      return (
        <Alert className="mt-3" variant="warning">
          Unsupported file type or too many files
        </Alert>
      );
    }

    return <></>;
  }

  AudioDropzoneContent({ isDragActive, isDragReject, values }) {
    if (this.shouldDisableAudioInput(values)) {
      return (
        <Alert className="mt-3" variant="secondary">
          Max number of files reached
        </Alert>
      );
    } else if (!isDragActive) {
      return <p className="mt-3">Drag or click to select files</p>;
    } else if (isDragActive && !isDragReject) {
      return <p className="mt-3">Drop files</p>;
    } else if (isDragActive && isDragReject) {
      return (
        <Alert className="mt-3" variant="warning">
          Unsupported file type or too many files
        </Alert>
      );
    }

    return <></>;
  }

  render() {
    const waypoint = this.props.waypoint || {};

    const initialValues = {
      name: waypoint.name || '',
      latitude: waypoint.latitude || undefined,
      longitude: waypoint.longitude || undefined,
      description: waypoint.description || undefined,
      images: waypoint.images || [],
      audio_clips: waypoint.audio_clips || [],
      departure_callout: waypoint.departure_callout || undefined,
      arrival_callout: waypoint.arrival_callout || undefined,

      image_files: [],
      image_alts: [],
      image_file_alts: [],

      audio_clip_files: [],
      audio_clip_file_texts: [],
    };

    if (waypoint.id) {
      initialValues.id = waypoint.id;
    }
    if (waypoint.group) {
      initialValues.group = waypoint.group;
    }
    if (waypoint.index !== undefined && waypoint.index != null) {
      initialValues.index = waypoint.index;
    }

    // You can do `(values, { setSubmitting })`
    // And use `setSubmitting(false)` to toggle button: `disabled={isSubmitting}`
    return (
      <Formik validationSchema={waypointSchema} initialValues={initialValues} onSubmit={this.onSubmit}>
        {({
          handleSubmit,
          isSubmitting,
          handleChange,
          handleBlur,
          values,
          setFieldValue,
          touched,
          isValid,
          errors,
        }) => (
          <Form noValidate onSubmit={handleSubmit} autoComplete="off">
            <Form.Group className="mb-3">
              <Form.Label className="me-2" aria-hidden="true">
                Name *
              </Form.Label>
              <Form.Control
                type="text"
                name="name"
                aria-label="Name"
                aria-describedby="nameHelpBlock"
                value={values.name}
                onChange={handleChange}
                onBlur={handleBlur}
                isInvalid={touched.name && !!errors.name}
              />
              <Form.Control.Feedback type="invalid">{errors.name}</Form.Control.Feedback>
              <Form.Text muted id="nameHelpBlock">
                How the app refers to this waypoint in callouts
              </Form.Text>
            </Form.Group>

            <Row>
              <Col>
                <Form.Group className="mb-3">
                  <Form.Label aria-hidden="true">Latitude *</Form.Label>
                  <Form.Control
                    type="number"
                    name="latitude"
                    aria-label="Latitude"
                    value={values.latitude}
                    onChange={handleChange}
                    onBlur={handleBlur}
                    isInvalid={touched.latitude && !!errors.latitude}
                  />
                  <Form.Control.Feedback type="invalid">{errors.latitude}</Form.Control.Feedback>
                </Form.Group>
              </Col>
              <Col>
                <Form.Group className="mb-3">
                  <Form.Label aria-hidden="true">Longitude *</Form.Label>
                  <Form.Control
                    type="number"
                    name="longitude"
                    aria-label="Longitude"
                    value={values.longitude}
                    onChange={handleChange}
                    onBlur={handleBlur}
                    isInvalid={touched.longitude && !!errors.longitude}
                  />
                  <Form.Control.Feedback type="invalid">{errors.longitude}</Form.Control.Feedback>
                </Form.Group>
              </Col>
            </Row>

            <Form.Group className="mb-3">
              <Form.Label className="me-2" aria-hidden="true">
                Description
              </Form.Label>

              <Form.Control
                as="textarea"
                rows={3}
                name="description"
                aria-label="Description"
                aria-describedby="descriptionHelpBlock"
                value={values.description}
                onChange={handleChange}
                onBlur={handleBlur}
                isInvalid={touched.description && !!errors.description}
              />
              <Form.Control.Feedback type="invalid">{errors.description}</Form.Control.Feedback>
              <Form.Text muted id="descriptionHelpBlock">
                Displayed in the app but not called out
              </Form.Text>
            </Form.Group>

            {shouldShowExtraWaypointInputs(this.state.waypointType) && (
              <>
                <Form.Group className="mb-3">
                  <Form.Label className="me-2" aria-hidden="true">
                    Departure Callout
                  </Form.Label>
                  <Form.Control
                    as="textarea"
                    rows={3}
                    name="departure_callout"
                    aria-label="Departure Callout"
                    aria-describedby="departureHelpBlock"
                    value={values.departure_callout}
                    onChange={handleChange}
                    onBlur={handleBlur}
                    isInvalid={touched.departure_callout && !!errors.departure_callout}
                  />
                  <Form.Control.Feedback type="invalid">{errors.departure_callout}</Form.Control.Feedback>
                  <Form.Text className="text-muted" id="departureHelpBlock">
                    Called out when a beacon is set on this waypoint
                  </Form.Text>
                </Form.Group>

                <Form.Group className="mb-3">
                  <Form.Label className="me-2" aria-hidden="true">
                    Arrival Callout
                  </Form.Label>
                  <Form.Control
                    as="textarea"
                    rows={3}
                    name="arrival_callout"
                    aria-label="Arrival Callout"
                    aria-describedby="arrivalHelpBlock"
                    value={values.arrival_callout}
                    onChange={handleChange}
                    onBlur={handleBlur}
                    isInvalid={touched.arrival_callout && !!errors.arrival_callout}
                  />
                  <Form.Control.Feedback type="invalid">{errors.arrival_callout}</Form.Control.Feedback>
                  <Form.Text className="text-muted" id="arrivalHelpBlock">
                    Called out when the user arrives at this waypoint
                  </Form.Text>
                </Form.Group>

                {shouldShowMediaInputs(this.props.activity) && (
                  <>
                    <Form.Group className="mb-3">
                      <Form.Group>
                        <Form.Label className="me-2">Images</Form.Label>
                      </Form.Group>

                      <Dropzone
                        accept={{ 'image/jpeg': ['.jpeg', '.jpg'], 'image/png': ['.png'] }}
                        maxFiles={MAX_MEDIA_FILES}
                        disabled={this.shouldDisableImageInput(values)}
                        onDrop={(acceptedFiles, fileRejections) => {
                          const totalFiles = values.images.length + values.image_files.length + acceptedFiles.length;
                          if (totalFiles > MAX_MEDIA_FILES || fileRejections.length > MAX_MEDIA_FILES) {
                            const error = new Error(`Max number of supported files is ${MAX_MEDIA_FILES}`);
                            error.title = 'Cannot Add Files';
                            showError(error);
                            return;
                          }

                          if (acceptedFiles.length === 0) {
                            return;
                          }

                          const images = values.image_files.concat(acceptedFiles);
                          setFieldValue('image_files', images);

                          let image_file_alts = values.image_file_alts.concat(Array(acceptedFiles.length).fill(''));
                          setFieldValue('image_file_alts', image_file_alts);
                        }}>
                        {({ getRootProps, getInputProps, isDragActive, isDragAccept, isDragReject }) => {
                          const additionalClass = isDragAccept ? 'accept' : isDragReject ? 'reject' : '';
                          return (
                            <Container style={dropzoneStyle}>
                              <div
                                {...getRootProps({
                                  className: `dropzone ${additionalClass}`,
                                })}>
                                <input {...getInputProps()} />
                                <this.ImageDropzoneContent
                                  isDragActive={isDragActive}
                                  isDragReject={isDragReject}
                                  values={values}
                                />
                              </div>
                            </Container>
                          );
                        }}
                      </Dropzone>

                      <Form.Text className="text-muted">
                        Max {MAX_MEDIA_FILES} files. Supported file formats include JPEG, JPG and PNG.
                      </Form.Text>

                      <aside className="mb-2 mt-2">
                        {values.images &&
                          values.images.map((image, i) => (
                            <div className="mb-3" key={image.id}>
                              <ImageThumb src={image.media_url} alt={image.description} thumbnail fluid />
                              <OverlayTrigger
                                overlay={
                                  <Tooltip>This action will delete the item instantly without pressing Save</Tooltip>
                                }>
                                <Button
                                  className="mt-2"
                                  variant="danger"
                                  size="sm"
                                  onClick={() => {
                                    const toastId = showLoading('Deleting image...');

                                    API.deleteWaypointMedia(image.id)
                                      .then(() => {
                                        const images = values.images;
                                        images.splice(i, 1);
                                        setFieldValue('images', images);
                                      })
                                      .catch((error) => {
                                        dismissLoading(toastId);
                                        error.title = 'Error deleting image';
                                        showError(error);
                                      })
                                      .finally(() => {
                                        dismissLoading(toastId);
                                      });
                                  }}>
                                  Delete
                                </Button>
                              </OverlayTrigger>
                            </div>
                          ))}

                        {values.image_files &&
                          values.image_files.map((file, i) => (
                            <div className="mb-3" key={file.path}>
                              <Form.Group className="mt-1 mb-3">
                                <ImageThumb file={file} alt={values.image_file_alts[i]} />
                                <Form.Control
                                  as="textarea"
                                  rows={1}
                                  placeholder="Alt text"
                                  name={`image_file_alts[${i}]`}
                                  aria-label="Alt text"
                                  value={values.image_file_alts[i]}
                                  onChange={handleChange}
                                  onBlur={handleBlur}
                                />
                                <Button
                                  className="mt-2"
                                  variant="danger"
                                  size="sm"
                                  onClick={() => {
                                    const images = values.image_files;
                                    images.splice(i, 1);
                                    setFieldValue('image_files', images);

                                    let image_file_alts = values.image_file_alts;
                                    image_file_alts.splice(i, 1);
                                    setFieldValue('image_file_alts', image_file_alts);
                                  }}>
                                  Delete
                                </Button>
                              </Form.Group>
                            </div>
                          ))}
                      </aside>
                    </Form.Group>
                    <Form.Group className="mb-3">
                      <Form.Group>
                        <Form.Label className="me-2">Audio Clips</Form.Label>
                      </Form.Group>

                      <Dropzone
                        accept={{
                          'audio/mpeg': ['.mp3'],
                          'audio/x-m4a': ['.m4a'],
                          'audio/aac': ['.aac'],
                        }}
                        maxFiles={MAX_MEDIA_FILES}
                        disabled={this.shouldDisableAudioInput(values)}
                        onDrop={(acceptedFiles, fileRejections) => {
                          const totalFiles =
                            values.audio_clips.length + values.audio_clip_files.length + acceptedFiles.length;
                          if (totalFiles > MAX_MEDIA_FILES || fileRejections.length > MAX_MEDIA_FILES) {
                            const error = new Error(`Max number of supported files is ${MAX_MEDIA_FILES}`);
                            error.title = 'Cannot Add Files';
                            showError(error);
                            return;
                          }

                          if (acceptedFiles.length === 0) {
                            return;
                          }

                          const audio_clip_files = values.audio_clip_files.concat(acceptedFiles);
                          setFieldValue('audio_clip_files', audio_clip_files);

                          let audio_clip_file_texts = values.audio_clip_file_texts.concat(
                            Array(acceptedFiles.length).fill(''),
                          );

                          setFieldValue('audio_clip_file_texts', audio_clip_file_texts);
                        }}>
                        {({ getRootProps, getInputProps, isDragActive, isDragAccept, isDragReject }) => {
                          const additionalClass = isDragAccept ? 'accept' : isDragReject ? 'reject' : '';
                          return (
                            <Container style={dropzoneStyle}>
                              <div
                                {...getRootProps({
                                  className: `dropzone ${additionalClass}`,
                                })}>
                                <input {...getInputProps()} />
                                <this.AudioDropzoneContent
                                  isDragActive={isDragActive}
                                  isDragReject={isDragReject}
                                  values={values}
                                />
                              </div>
                            </Container>
                          );
                        }}
                      </Dropzone>

                      <Form.Text className="text-muted">
                        Max {MAX_MEDIA_FILES} files. Supported file formats include MP3, AAC and M4A.
                      </Form.Text>

                      <aside className="mb-2 mt-3">
                        {values.audio_clips &&
                          values.audio_clips.map((audio_clip, i) => (
                            <div className="mb-3" key={audio_clip.id}>
                              <AudioClip
                                key={`audio_clip-${audio_clip.id}`}
                                src={audio_clip.media_url}
                                description={audio_clip.description}
                              />
                              <OverlayTrigger
                                overlay={
                                  <Tooltip>This action will delete the item instantly without pressing Save</Tooltip>
                                }>
                                <Button
                                  className="mt-2"
                                  variant="danger"
                                  size="sm"
                                  onClick={() => {
                                    const toastId = showLoading('Deleting audio clip...');

                                    API.deleteWaypointMedia(audio_clip.id)
                                      .then(() => {
                                        const audio_clips = values.audio_clips;
                                        audio_clips.splice(i, 1);
                                        setFieldValue('audio_clips', audio_clips);
                                      })
                                      .catch((error) => {
                                        dismissLoading(toastId);
                                        error.title = 'Error deleting audio clip';
                                        showError(error);
                                      })
                                      .finally(() => {
                                        dismissLoading(toastId);
                                      });
                                  }}>
                                  Delete
                                </Button>
                              </OverlayTrigger>
                            </div>
                          ))}

                        {values.audio_clip_files &&
                          values.audio_clip_files.map((file, i) => (
                            <Form.Group className="mt-1 mb-2" key={file.path}>
                              <AudioClip
                                key={`audio_clip-${file.path}`}
                                file={file}
                                alt={values.audio_clip_file_texts[i]}
                              />
                              <Form.Control
                                as="textarea"
                                rows={1}
                                placeholder="Audio description"
                                name={`audio_clip_file_texts[${i}]`}
                                aria-label="Audio description"
                                value={values.audio_clip_file_texts[i]}
                                onChange={handleChange}
                                onBlur={handleBlur}
                              />
                              <Button
                                className="mt-2"
                                variant="danger"
                                size="sm"
                                onClick={() => {
                                  const audio_clip_files = values.audio_clip_files;
                                  audio_clip_files.splice(i, 1);
                                  setFieldValue('audio_clip_files', audio_clip_files);

                                  let audio_clip_file_texts = values.audio_clip_file_texts;
                                  audio_clip_file_texts.splice(i, 1);
                                  setFieldValue('audio_clip_file_texts', audio_clip_file_texts);
                                }}>
                                Delete
                              </Button>
                            </Form.Group>
                          ))}
                      </aside>
                    </Form.Group>
                  </>
                )}
              </>
            )}

            <Button
              variant="primary"
              type="submit"
              disabled={!isValid || isSubmitting || (!this.props.waypoint && Object.keys(touched).length === 0)}>
              {this.props.waypoint ? 'Save' : 'Submit'}
            </Button>
          </Form>
        )}
      </Formik>
    );
  }
}
