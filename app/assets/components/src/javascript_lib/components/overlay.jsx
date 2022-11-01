import React from 'react';
import PropTypes from 'prop-types';

import applyComponentDecorators from 'javascript_lib/utils/apply_component_decorators';

import 'javascript_lib/styles/overlay.scss';


class overlay extends React.Component {

  constructor(props) {
    super(props);
  }

  render() {
    return(
      <div className={this.props.show ? "overlay" : "overlay overlay--fade-out"}>
        {this.props.children}
      </div>
    );
  }
}

overlay.propTypes = {
  children: PropTypes.node,
  show: PropTypes.bool
};

overlay.defaultProps = {
  children: null,
  show: true
};

export default applyComponentDecorators(overlay);
