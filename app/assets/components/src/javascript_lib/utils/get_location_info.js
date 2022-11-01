import window from 'window-or-global';


export function getHref() {
  return window.location.href;
}

export function getProtocol() {
  return window.location.protocol;
}

export function getHost() {
  return window.location.host;
}

export function getHostname() {
  return window.location.hostname;
}

export function getPort() {
  return window.location.port;
}

export function getPath() {
  return window.location.pathname;
}

export function getHostWithProtocol() {
  return getProtocol() + "//" + getHost();
}
