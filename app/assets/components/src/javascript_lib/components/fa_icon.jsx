import React from 'react';
import PropTypes from 'prop-types';

import applyComponentDecorators from 'javascript_lib/utils/apply_component_decorators';

import 'javascript_lib/styles/fa_icon.scss';


class FaIcon extends React.Component {

  constructor(props) {
    super(props);
  }

  _getClassName() {
    return "fa fa-icon--" + this.props.size + " fa-" + this.props.type + " " + this.props.faIconClassName;
  }

  render() {
    return(
      <i className={this._getClassName()} />
    );
  }
}

FaIcon.propTypes = {
  type: PropTypes.string.isRequired,
  size: PropTypes.string,
  faIconClassName: PropTypes.string
};

FaIcon.defaultProps = {
  size: "medium",
  faIconClassName: ""
};

export default applyComponentDecorators(FaIcon);
