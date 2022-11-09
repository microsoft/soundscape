// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

import React from 'react';
import { Image } from 'react-bootstrap';

export default class ImageThumb extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      loading: true,
      thumb: undefined,
      alt: undefined,
    };
  }

  componentDidMount() {
    if (this.props.src) {
      this.setState({ loading: false, thumb: this.props.src, alt: this.props.alt });
    } else if (this.props.file) {
      this.setState({ loading: true });
      this.loadFile(this.props.file);
    }
  }

  loadFile = (file) => {
    let reader = new FileReader();

    reader.onloadend = () => {
      this.setState({ loading: false, thumb: reader.result });
    };

    reader.readAsDataURL(file);
  };

  render() {
    const { src, file } = this.props;
    if (!src && !file) {
      return null;
    }

    const { loading } = this.state;

    if (loading) {
      return <p>loading...</p>;
    }

    const { thumb } = this.state;

    return (
      <>
        <Image className="mb-2" src={thumb} alt={this.state.alt} thumbnail fluid height={160} width={160} />
        <p className="mb-1">{this.state.alt}</p>
      </>
    );
  }
}
