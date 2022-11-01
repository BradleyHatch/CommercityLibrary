import Actual from 'actual';


export function getDeviceDimensions() {
  return {
    width: Actual("width", "px"),
    height: Actual("height", "px")
  };
}
