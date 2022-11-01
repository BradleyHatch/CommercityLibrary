import moment from 'moment';


export function dateFormat(dateString) {
  return new moment(dateString).format('Do MMMM YYYY');
}
