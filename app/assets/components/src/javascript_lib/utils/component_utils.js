import window from 'window-or-global';


export function setComponentInterval(component, intervalName, intervalPeriod, funcToCall, noWaitForFirstCall=true) {
  if(noWaitForFirstCall) {
    funcToCall();
  }

  const interval = window.setInterval(funcToCall, intervalPeriod);

  component.setState({ [intervalName]: interval });
}

export function clearComponentInterval(component, intervalName) {
  window.clearInterval(component.state[intervalName]);

  component.setState({[intervalName]: null});
}

export function justClearInterval(interval) {
  window.clearInterval(interval);
}

export function setComponentTimeout(component, intervalName, intervalPeriod, funcToCall) {
  const interval = window.setTimeout(funcToCall, intervalPeriod);

  component.setState({ [intervalName]: interval });
}

export function clearComponentTimeout(timeout) {
  window.clearInterval(timeout);
}
