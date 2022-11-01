import React from 'react';
import PropTypes from 'prop-types';
import shortid from 'shortid';
import Immutable from 'immutable';

import applyComponentDecorators from 'javascript_lib/utils/apply_component_decorators';

import Panel from 'javascript_lib/components/panel';
import Modal from 'javascript_lib/components/modal';
import BackgroundJob from 'components/background_jobs/background_job';

import { connect } from "react-redux"

import 'styles/background_jobs_modal.scss';

import { fetchJobs } from 'actions/background_job_actions'

@connect((store) => {
  return {
    open: store.background_jobs.modal_open,
    jobs: store.background_jobs.jobs
  }
}, (dispatch) => {
  return {
    fetchJobs: () => dispatch(fetchJobs())
  }
})
export default class BackgroundJobsModal extends React.Component {

  componentWillMount() {
    this.props.fetchJobs()
  }

  _renderBackgroundJobs() {
    return this.props.jobs.map(job => <BackgroundJob key={job.id} job={job} />);
  }

  render() {
    return(
      <Modal open={this.props.open} toggle={this.props.modalToggle}>
        <Panel panelClassName="background-jobs-modal__panel">
          <div className="background-jobs-modal__inner-panel">
            {this._renderBackgroundJobs()}
          </div>
        </Panel>
      </Modal>
    );
  }
}

BackgroundJobsModal.propTypes = {
  modalToggle: PropTypes.func.isRequired,
}


// export default applyComponentDecorators(BackgroundJobsModal);
