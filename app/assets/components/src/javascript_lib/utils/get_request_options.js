import REQUEST_OPTIONS from 'javascript_lib/constants/requests/RequestOptions.js';
import REQUEST_HEADERS from 'javascript_lib/constants/requests/RequestHeaders.js';
import REQUEST_METHODS from 'javascript_lib/constants/requests/RequestMethods.js';
import REQUEST_CONTENT_TYPES from 'javascript_lib/constants/requests/RequestContentTypes.js';


function getRequestOptions(hostname, path, method, body) {
  return {
    [REQUEST_OPTIONS.BODY]: body,
    [REQUEST_OPTIONS.URL]: hostname + path,
    [REQUEST_OPTIONS.METHOD]: method,
    [REQUEST_OPTIONS.HEADERS]: {
      [REQUEST_HEADERS.CONTENT_TYPE]: REQUEST_CONTENT_TYPES.JSON
    }
  };
}

export function postMethodOptions(hostName, path, body=null) {
  return getRequestOptions(hostName, path,  REQUEST_METHODS.POST, body);
}

export function getMethodOptions(hostName, path, body=null) {
  return getRequestOptions(hostName, path,  REQUEST_METHODS.GET, body);
}

export function deleteMethodOptions(hostName, path, body=null) {
  return getRequestOptions(hostName, path,  REQUEST_METHODS.DELETE, body);
}
