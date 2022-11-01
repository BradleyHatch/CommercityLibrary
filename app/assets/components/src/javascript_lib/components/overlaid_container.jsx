import React from 'react';
import PropTypes from 'prop-types';

import applyComponentDecorators from 'javascript_lib/utils/apply_component_decorators';

import Overlay from 'javascript_lib/components/overlay';

import 'javascript_lib/styles/overlaid_container.scss';


class overlaid_container extends React.Component {

  constructor(props) {
    super(props);
  }

  _getContainerClassName() {
    let className = this.props.showOverlay
      ? "overlaid-container__container"
      : "overlaid-container__container overlaid-container__container--fade-in";

    if(this.props.containerClassName) {
      className + " " + this.props.containerClassName;
    }

    return className;
  }

  _renderContainer() {
    return(
      <div className={this._getContainerClassName()}>
        { this.props.containerChildren }
      </div>
    );
  }

  _renderOverlay() {
    return(
      <Overlay show={this.props.showOverlay}>
        { this.props.overlayChildren }
      </Overlay>
    );
  }

  render() {
    return(
      <div className="overlaid-container">
        {this._renderContainer()}
        {this._renderOverlay()}
      </div>
    );
  }
}

overlaid_container.propTypes = {
  containerClassName: PropTypes.string,
  overlayChildren: PropTypes.node,
  containerChildren: PropTypes.node,
  showOverlay: PropTypes.bool
};

overlaid_container.defaultProps = {
  containerClassName: null,
  children: null,
  showOverlay: true
};

export default applyComponentDecorators(overlaid_container);
