import  React from 'react';

import BackgroundJobsContainer from 'components/background_jobs_container';


import { Provider } from "react-redux"

import store from "utils/store"

export default function appComponents(type) {
  switch(type) {
    case 'BackgroundJobsContainer':
      return <Provider store={store}><BackgroundJobsContainer /></Provider>;
    default:
      return null;
  }
}
