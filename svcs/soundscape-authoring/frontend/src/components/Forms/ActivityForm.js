// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

import React from 'react';
import { Form, Button, Image } from 'react-bootstrap';
import { Formik } from 'formik';
import * as yup from 'yup';
import Activity from '../../data/Activity';

const activitySchema = yup.object().shape({
  name: yup.string().trim().required('Name is a required field'),
  description: yup.string().trim().required('Description is a required field'),
  author_name: yup.string().trim().required('Author is a required field'),
  type: yup.string().oneOf([Activity.TYPE.ORIENTEERING, Activity.TYPE.GUIDED_TOUR]),
  start: yup.date(),
  end: yup.date(),
  expires: yup.boolean(),
  image_url: yup.string().nullable(),
  image_alt: yup.string().trim(),

  image_file: yup.mixed(),
  image_filename: yup.string(),
});

export default class ActivityForm extends React.Component {
  render() {
    const activity = this.props.activity ?? {};

    const initialValues = {
      name: activity.name || '',
      description: activity.description || '',
      author_name: activity.author_name || '',
      type: activity.type || Activity.TYPE.ORIENTEERING,
      start: activity.start || undefined,
      end: activity.end || undefined,
      expires: activity.expires || undefined,
      image_url: activity.image_url || undefined,
      image_alt: activity.image_alt || undefined,

      image_file: undefined,
      image_filename: undefined,
    };

    // In order to make the HTML form show the dates, we need to remove the last Z character.
    if (initialValues.start && initialValues.start.length > 0 && initialValues.start.substr(-1) === 'Z') {
      initialValues.start = initialValues.start.slice(0, -1);
    }

    if (initialValues.end && initialValues.end.length > 0 && initialValues.end.substr(-1) === 'Z') {
      initialValues.end = initialValues.end.slice(0, -1);
    }

    if (activity.id) {
      initialValues.id = activity.id;
    }

    if (activity.author_id) {
      initialValues.author_id = activity.author_id;
    }

    return (
      <Formik
        validationSchema={activitySchema}
        initialValues={initialValues}
        onSubmit={(values, { setSubmitting }) => {
          let activity = Object.assign({}, values);

          if (activity.image_file) {
            activity.image = activity.image_file;
            delete activity.image_file;
            delete activity.image_filename;
          }

          this.props.onSubmit(activity).finally(() => {
            setSubmitting(false);
          });
        }}>
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
                value={values.name}
                onChange={handleChange}
                onBlur={handleBlur}
                isInvalid={touched.name && !!errors.name}
              />
              <Form.Control.Feedback type="invalid">{errors.name}</Form.Control.Feedback>
            </Form.Group>

            <Form.Group className="mb-3">
              <Form.Label aria-hidden="true">Description *</Form.Label>
              <Form.Control
                as="textarea"
                rows={3}
                name="description"
                aria-label="Description"
                value={values.description}
                onChange={handleChange}
                onBlur={handleBlur}
                isInvalid={touched.description && !!errors.description}
              />
              <Form.Control.Feedback type="invalid">{errors.description}</Form.Control.Feedback>
            </Form.Group>

            <Form.Group className="mb-3">
              <Form.Label className="me-2" aria-hidden="true">
                Author / Organization *
              </Form.Label>
              <Form.Control
                type="text"
                name="author_name"
                aria-label="Author / Organization"
                value={values.author_name}
                onChange={handleChange}
                onBlur={handleBlur}
                isInvalid={touched.author_name && !!errors.author_name}
              />
              <Form.Control.Feedback type="invalid">{errors.author_name}</Form.Control.Feedback>
            </Form.Group>

            <Form.Group className="mb-3">
              <Form.Label className="me-2" aria-hidden="true">
                Activity Type
              </Form.Label>
              <Form.Select
                name="type"
                aria-label="Activity type"
                value={values.type}
                onChange={handleChange}
                onBlur={handleBlur}
                isInvalid={touched.type && !!errors.type}
                disabled={this.props.activity}>
                <option value={Activity.TYPE.ORIENTEERING}>Orienteering</option>
                <option value={Activity.TYPE.GUIDED_TOUR}>Guided Tour</option>
              </Form.Select>
              <Form.Control.Feedback type="invalid">{errors.type}</Form.Control.Feedback>
            </Form.Group>

            <Form.Text className="text-muted" id="endHelpBlock">
              For the start & end dates, please use{' '}
              <a href="https://www.bing.com/search?q=utc%20time" target="_blank" rel="noreferrer">
                UTC time
              </a>{' '}
              (i.e., without a timezone)
            </Form.Text>

            <Form.Group className="mb-3">
              <Form.Label className="me-2" aria-hidden="true">
                Start Date
              </Form.Label>
              <Form.Control
                type="datetime-local"
                name="start"
                aria-label="Start date"
                value={values.start}
                onChange={handleChange}
                onBlur={handleBlur}
                isInvalid={touched.start && !!errors.start}
              />
              <Form.Control.Feedback type="invalid">{errors.start}</Form.Control.Feedback>
            </Form.Group>

            <Form.Group className="mb-3">
              <Form.Label className="me-2" aria-hidden="true">
                End Date
              </Form.Label>
              <Form.Control
                type="datetime-local"
                name="end"
                aria-label="End date"
                value={values.end}
                onChange={handleChange}
                onBlur={handleBlur}
                isInvalid={touched.end && !!errors.end}
              />
              <Form.Control.Feedback type="invalid">{errors.end}</Form.Control.Feedback>
            </Form.Group>

            {(values.expires || values.end) && (
              <Form.Group className="mb-3">
                <Form.Check
                  type="checkbox"
                  name="expires"
                  value={values.expires}
                  checked={values.expires}
                  onChange={handleChange}
                  onBlur={handleBlur}
                  label="Expires"
                  aria-describedby="expiresHelpBlock"
                />
                <Form.Text className="text-muted" id="expiresHelpBlock">
                  If selected, the activity will be unavailable to start on the app after the end date.
                </Form.Text>
              </Form.Group>
            )}

            <Form.Group className="mb-3">
              <Form.Group>
                <Form.Label className="me-2">Image</Form.Label>
              </Form.Group>

              {values.image_url && (
                <>
                  <Form.Group>
                    <Image className="mb-2" src={values.image_url} alt="Featured Image" thumbnail fluid />
                  </Form.Group>
                  <Form.Text>Select a new file to replace the existing image.</Form.Text>
                </>
              )}

              {values.image_file && (
                <>
                  <Form.Group>
                    <Image
                      className="mb-2"
                      src={URL.createObjectURL(values.image_file)}
                      alt="Featured Image"
                      thumbnail
                      fluid
                    />
                  </Form.Group>
                </>
              )}

              <Form.Group>
                <Form.Control
                  type="file"
                  accept="image/jpeg, image/jpg, image/png"
                  name="image_filename"
                  value={values.image_filename}
                  onChange={(event) => {
                    const imageFile = event.currentTarget.files[0];
                    setFieldValue('image_file', imageFile);
                    setFieldValue('image_url', null);
                    handleChange(event);
                  }}
                  onBlur={handleBlur}
                  isInvalid={touched.image_file && !!errors.image_file}
                />
              </Form.Group>
              <Form.Control.Feedback type="invalid">{errors.image_file}</Form.Control.Feedback>
              <Form.Text className="text-muted">Supported file formats include JPEG, JPG and PNG.</Form.Text>
            </Form.Group>

            {(values.image_alt || values.image_filename || values.image_url) && (
              <Form.Group className="mb-3">
                <Form.Label aria-hidden="true">Image Alt Text</Form.Label>
                <Form.Control
                  as="textarea"
                  rows={2}
                  name="image_alt"
                  aria-label="Image Alt"
                  value={values.image_alt}
                  onChange={handleChange}
                  onBlur={handleBlur}
                  isInvalid={touched.image_alt && !!errors.image_alt}
                />
                <Form.Control.Feedback type="invalid">{errors.image_alt}</Form.Control.Feedback>
              </Form.Group>
            )}

            <Button
              variant="primary"
              type="submit"
              disabled={!isValid || isSubmitting || (!this.props.activity && Object.keys(touched).length === 0)}>
              {this.props.activity ? 'Save' : 'Continue'}
            </Button>
          </Form>
        )}
      </Formik>
    );
  }
}
