const popsicle = require('popsicle');

import {
  postMethodOptions,
  getMethodOptions,
  deleteMethodOptions
} from 'javascript_lib/utils/get_request_options';
import { getHostWithProtocol } from 'javascript_lib/utils/get_location_info';

export default class RequestRepository {

  _makeRequest(request) {
    return popsicle.request(request)
    .use(popsicle.plugins.parse('json'))
    .then(response => response.body)
    .catch(error => error.body);
  }

  postToHost(path, body=null) {
    return this.post(getHostWithProtocol(), path, body);
  }

  post(hostname, path, body=null) {
    return this._makeRequest(postMethodOptions(hostname, path, body));
  }

  getToHost(path, body=null) {
    return this.get(getHostWithProtocol(), path, body);
  }

  get(hostname, path, body=null) {
    return this._makeRequest(getMethodOptions(hostname, path, body));
  }

  deleteToHost(path, body=null) {
    return this.delete(getHostWithProtocol(), path, body);
  }

  delete(hostname, path, body=null) {
    return this._makeRequest(deleteMethodOptions(hostname, path, body));
  }
}
