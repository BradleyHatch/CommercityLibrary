import React from 'react';
import PropTypes from 'prop-types';

import applyComponentDecorators from 'javascript_lib/utils/apply_component_decorators';

import ProgressCircle from 'javascript_lib/components/progress_circle';

import 'javascript_lib/styles/state_display_light.scss';

import STATE_LIGHT_STATES from 'javascript_lib/constants/component_state/state_light_states';


class StateDisplayLight extends React.Component {

  constructor(props) {
    super(props);
  }

  _getLightClassNames(lightState) {
    let classNames = "state-display-light__light";

    switch(lightState) {

      case STATE_LIGHT_STATES.PROCESSING:
        classNames += " state-display-light__light--processing";
        break;
      case STATE_LIGHT_STATES.NEGATIVE:
        classNames += " state-display-light__light--negative";
        break;
      case STATE_LIGHT_STATES.WARNING:
        classNames += " state-display-light__light--warning";
        break;
        default:
        classNames += " state-display-light__light--positive";
    }

    if(this.props.lightClassName) {
      classNames += " " + this.props.lightClassName;
    }

    return classNames;
  }

  render() {
    if(this.props.lightState === STATE_LIGHT_STATES.PROCESSING) {
      return(
        <ProgressCircle white={this.props.progressWhite}/>
      );
    } else {
      return(
        <span className={this.props.className ? "state-display-light " + this.props.className : "state-display-light"}>
          <div className={this._getLightClassNames(this.props.lightState)}></div>
        </span>
      );
    }
  }
}

StateDisplayLight.propTypes = {
  lightState: PropTypes.number,
  className: PropTypes.string,
  lightClassName: PropTypes.string,
  progressWhite: PropTypes.bool
}

StateDisplayLight.defaultProps = {
  className: null,
  lightClassName: null,
  progressWhite: false
}

export default applyComponentDecorators(StateDisplayLight);
