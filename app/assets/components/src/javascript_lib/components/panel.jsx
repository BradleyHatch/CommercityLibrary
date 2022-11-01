import React from 'react';
import PropTypes from 'prop-types';

import applyComponentDecorators from 'javascript_lib/utils/apply_component_decorators';

import 'javascript_lib/styles/panel.scss';


class Panel extends React.Component {

  constructor(props) {
    super(props);
  }

  render() {
    return(
      <div className={this.props.panelClassName ? "panel " + this.props.panelClassName : "panel" }>
        {this.props.children}
      </div>
    );
  }
}

Panel.propTypes = {
  children: PropTypes.node,
  panelClassName: PropTypes.string
};

Panel.defaultProps = {
  children: null,
  panelClassName: null
};

export default applyComponentDecorators(Panel);
