import React from 'react';
import PropTypes from 'prop-types';

import applyComponentDecorators from 'javascript_lib/utils/apply_component_decorators';

import 'javascript_lib/styles/app_bar.scss';


class AppBar extends React.Component {

  constructor(props) {
    super(props);
  }

  render() {
    return(
      <div className={this.props.appBarClassName ? "app-bar " + this.props.appBarClassName : "app-bar" } >
        {this.props.children}
      </div>
    );
  }
}

AppBar.propTypes = {
  children: PropTypes.node,
  appBarClassName: PropTypes.string
};

AppBar.defaultProps = {
  children: null,
  appBarClassName: null
};

export default applyComponentDecorators(AppBar);
