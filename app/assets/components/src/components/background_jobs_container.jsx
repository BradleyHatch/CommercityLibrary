import React from 'react';

import StateDisplayLight from 'javascript_lib/components/state_display_light';
import Clickable from 'javascript_lib/components/clickable';
import BackgroundJobsModal from 'components/background_jobs/background_jobs_modal';

import 'styles/background_jobs.scss';

import { connect } from "react-redux"

import STATE_LIGHT_STATES from 'javascript_lib/constants/component_state/state_light_states';

@connect((state)=>{
  return {
    jobs: state.background_jobs.jobs,
  }
}, (dispatch) => {
  return {
    toggleModal: () => dispatch({type: 'TOGGLE_JOBS_MODAL'}),
  }
})
export default class BackgroundJobsContainer extends React.Component {

  _light(status) {
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

  _mainLight() {
    let worst = "UNKNOWN"
    for(const job_key in this.props.jobs) {
      const job = this.props.jobs[job_key]
      if (job.status == 'failed') {
        worst = 'failed'
        break
      }
      if (job.status == 'warning') worst = 'warning'
    }
    return this._light(worst);
  }

  render() {
    const main_light = this._mainLight()
    return(
      <span className="background-jobs">
        <Clickable clickableClassName="background-jobs__button">
          <StateDisplayLight lightState={main_light} progressWhite={true} />
          <div className="background-jobs__button-title" onClick={this.props.toggleModal}>
            Service Status
          </div>
        </Clickable>
        <BackgroundJobsModal updateMainLight={this._mainLight.bind(this)} modalToggle={this.props.toggleModal} />
      </span>
    );
  }
}
