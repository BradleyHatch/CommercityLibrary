const initialState = {
  jobs: [],
  fetching: true,
  fetched: false,
  modal_open: false
}

export default function reducer(state=initialState, action) {
  switch (action.type) {
    case 'TOGGLE_JOBS_MODAL':
      return {...state, modal_open: !state.modal_open}
    case 'FETCH_JOBS':
      return {...state, fetching: true}
    case 'UPDATE_JOBS':
      return {...state, jobs: action.payload.jobs}
    case 'FETCH_JOBS_FULFILLED':
      return {...state,
        jobs: action.payload.jobs,
        fetching: false,
        fetched: true}
  }
  return state
}
