import React from 'react';
import PropTypes from 'prop-types';
import Spinner from 'react-spinkit'


import applyComponentDecorators from 'javascript_lib/utils/apply_component_decorators';

import 'javascript_lib/styles/progress_circle.scss';
import 'javascript_lib/styles/spinner.scss';


class ProgressCircle extends React.Component {

  constructor(props) {
    super(props);
  }

  _getSpinnerCustomeClasses() {
    if(this.props.white) {
      return "custom-spinner custom-light-spinner";
    }

    return "custom-spinner";
  }

  render() {
    return(
      <div className="progress-circle">
        <Spinner spinnerName="double-bounce" noFadeIn={true} overrideSpinnerClassName={this._getSpinnerCustomeClasses()} />
      </div>
    );
  }
}

ProgressCircle.propTypes = {
  white: PropTypes.bool
}

ProgressCircle.defaultProps = {
  white: false
}

export default applyComponentDecorators(ProgressCircle);
