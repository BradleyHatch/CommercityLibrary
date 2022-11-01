import React from 'react';
import PropTypes from 'prop-types';

import applyComponentDecorators from 'javascript_lib/utils/apply_component_decorators';

import 'javascript_lib/styles/clickable.scss';


class Clickable extends React.Component {

  constructor(props) {
    super(props);
  }

  _handleClick() {
    if(this.props.onClick) {
      this.props.onClick();
    }
  }

  render() {
    return(
      <div
        className={this.props.clickableClassName ? "clickable " + this.props.clickableClassName : "clickable" }
        onClick={this._handleClick}
        style={this.props.style}
      >
        {this.props.children}
      </div>
    );
  }
}

Clickable.propTypes = {
  onClick: PropTypes.func,
  children: PropTypes.node,
  clickableClassName: PropTypes.string,
  style: PropTypes.object
};

Clickable.defaultProps = {
  onClick: null,
  children: null,
  clickableClassName: null,
  style: {}
};

export default applyComponentDecorators(Clickable);
