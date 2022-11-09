// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

import React from 'react';
import { Form, Button } from 'react-bootstrap';
import { Formik } from 'formik';
import * as yup from 'yup';
import GPXCard from '../ActivitySecondary/GPXCard';
import { fileToGPX, isGPXFileValid } from '../../utils/GPXUtils';

const activitySchema = yup.object().shape({
  file: yup
    .mixed()
    .required('Please select a GPX file')
    .test('is-gpx-valid', 'Please select a valid and non-empty GPX file', async (value) => isGPXFileValid(value)),
});

export default class ActivityImportForm extends React.Component {
  importGPX = (gpx) => {
    this.props.onSubmit(gpx);
  };

  render() {
    return (
      <Formik
        validationSchema={activitySchema}
        initialValues={{ filename: undefined, file: undefined, gpx: undefined }}
        onSubmit={(values) => {
          this.importGPX(values.file);
        }}>
        {({ handleSubmit, handleChange, handleBlur, values, setFieldValue, touched, isValid, errors }) => (
          <Form noValidate onSubmit={handleSubmit} autoComplete="off">
            <Form.Group>
              <Form.Group>
                <Form.Label>Select a previously exported activity (GPX file):</Form.Label>
              </Form.Group>

              <Form.Group>
                <Form.Control
                  className="mb-3"
                  type="file"
                  accept=".gpx, application/gpx+xml, application/octet-stream"
                  name="filename"
                  value={values.filename}
                  onBlur={handleBlur}
                  isInvalid={touched.filename && !!errors.file}
                  onChange={(event) => {
                    const file = event.currentTarget.files[0];
                    setFieldValue('file', file);
                    handleChange(event);

                    fileToGPX(file)
                      .then((gpx) => {
                        setFieldValue('gpx', gpx);
                      })
                      .catch(() => {
                        setFieldValue('gpx', undefined);
                      })
                      .finally(() => {
                        handleChange(event);
                      });
                  }}
                />
                <Form.Control.Feedback className="mb-2" type="invalid">
                  {errors.file}
                </Form.Control.Feedback>
                {values.gpx && <GPXCard gpx={values.gpx} />}
              </Form.Group>
            </Form.Group>

            <Button variant="primary" type="submit" disabled={Object.keys(touched).length === 0 || !isValid}>
              Import
            </Button>
          </Form>
        )}
      </Formik>
    );
  }
}
