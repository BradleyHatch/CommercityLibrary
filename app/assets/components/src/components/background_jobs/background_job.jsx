import React from 'react';
import PropTypes from 'prop-types';

import applyComponentDecorators from 'javascript_lib/utils/apply_component_decorators';

import StateDisplayLight from 'javascript_lib/components/state_display_light';

import 'styles/background_job.scss';

import STATE_LIGHT_STATES from 'javascript_lib/constants/component_state/state_light_states';


class BackgroundJob extends React.Component {


  _light() {
    const { status } = this.props.job
    switch(status) {
      case 'processing':
        return STATE_LIGHT_STATES.PROCESSING;
      case 'warning':
        return STATE_LIGHT_STATES.WARNING;
      case 'failed':
        return STATE_LIGHT_STATES.NEGATIVE;
      default:
        return STATE_LIGHT_STATES.POSITIVE;
    }
  }

  _name() {
    return this.props.job.name
  }

  _processingText() {
    const { status, job_size, job_processed_count } = this.props.job
    let processingText = ''
    if(status === 'processing') {
      processingText +=  ' - Processing';

      if(job_processed_count > 0) {
        processingText += ` (${job_processed_count}/${job_size})`
      }
    }
    return processingText
  }

  render() {
    return(
      <div className="background-job">
        <div className="background-job__light">
          <StateDisplayLight lightState={this._light()} />
        </div>
        <div className="background-job__name">
          <b>{ this._name() } </b>
          <i>{ this._processingText() }</i>
        </div>
      </div>
    );
  }
}

BackgroundJob.propTypes = {
  job: PropTypes.object,
};

export default applyComponentDecorators(BackgroundJob);
