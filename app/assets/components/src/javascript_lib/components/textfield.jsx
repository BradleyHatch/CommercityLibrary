import React from 'react';
import PropTypes from 'prop-types';

import applyComponentDecorators from 'javascript_lib/utils/apply_component_decorators';

import 'javascript_lib/styles/textfield.scss';


class Textfield extends React.Component {

  constructor(props) {
    super(props);
  }

  _handleChange(event) {
    this.props.handleChange(event.target.value);
  }

  render() {
    return(
      <input
        value={this.props.value}
        type="text"
        className={this.props.className ? "textfield " + this.props.className : "textfield" }
        onChange={this._handleChange}
      />
    );
  }
}

Textfield.propTypes = {
  handleChange: PropTypes.func.isRequired,
  value: PropTypes.string.isRequired,
  children: PropTypes.node,
  className: PropTypes.string
};

Textfield.defaultProps = {
  children: null,
  className: null
};

export default applyComponentDecorators(Textfield);
