// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

import React from 'react';

export default class AudioClip extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      loading: true,
      src: undefined,
      description: undefined,
    };
  }

  componentDidMount() {
    if (this.props.src) {
      this.setState({ loading: false, src: this.props.src, description: this.props.description });
    } else if (this.props.file) {
      this.setState({ loading: true });
      this.loadFile(this.props.file);
    }
  }

  loadFile = (file) => {
    let reader = new FileReader();

    reader.onloadend = () => {
      this.setState({ loading: false, src: reader.result });
    };

    reader.readAsDataURL(file);
  };

  render() {
    if (!this.props.src && !this.props.file) {
      return null;
    }

    const { loading } = this.state;

    if (loading) {
      return <p>loading...</p>;
    }

    const { src } = this.state;

    return (
      <>
        <audio className="mt-2" controls>
          <source src={src} />
          Your browser does not support HTML audio playback.
        </audio>
        <p className="mb-2">{this.state.description}</p>
      </>
    );
  }
}
