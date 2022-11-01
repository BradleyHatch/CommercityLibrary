import window from 'window-or-global';


export function createConnection(channel_name, identifier, dispatch) {
  const connected = () => { dispatch({type: 'CONNECTION_ESTABLISHED', payload: { channel_name }}) }
  const disconnected = () => { dispatch({type: 'CONNECTION_DROPPED', payload: { channel_name }}) }
  const received = (data) => { dispatch(data) }

  return window.App.cable.subscriptions.create(identifier, {
    connected, disconnected, received
  });
}


export const actionCableMiddleware = store => next => action => {
  let newState = next(action)
  if (action.type === 'CONNECTION_ESTABLISHED') {
    const toRun = store.getState().connections[action.payload.channel_name].on_connect_actions;
    if (toRun.length > 0) {
      toRun.map((action) => store.dispatch(action))
      store.dispatch({type: 'CHANNEL_CONNECTION_ACTIONS_RUN', payload: { channel_name: action.payload.channel_name}})
    }
  }
  return newState;
}


export function normalizeChannelName(identifier) {
  if (typeof identifier === 'object') {
    return Object.keys(identifier).map((key)=>{
        return `${key}:${identifier[key]}`
      }).join('|');
  }
  return identifier;
}
