import { with_connection } from 'utils/action_cable'


export function fetchJobs() {
  return with_connection('BackgroundJobsChannel', (connection) => {
    connection.perform('fetch_jobs')
    return {type: 'FETCH_JOBS'}
  })
}
