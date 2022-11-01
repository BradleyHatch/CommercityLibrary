import createReducer from './action_cable/reducer'
import {
  createConnection,
  actionCableMiddleware,
  normalizeChannelName,
} from './action_cable/utils'

export function with_connection(channel_identifier, action) {
  const channel_name = normalizeChannelName(channel_identifier)

  return function(dispatch, getState){

    const getConnection = () => getState().connections[channel_name]

    if (getConnection() == undefined) {
      dispatch(registerChannel(channel_name, channel_identifier))
    }

    if (getConnection().connection == undefined) {
      dispatch({
        type: 'CONNECT_CHANNEL',
        payload: {
          channel_name,
          connection: createConnection(channel_name, getConnection().identifier, dispatch)
        }
      })
    }

    const connection = getConnection().connection;

    if (getConnection().connected == false) {
      const wrapped_action = () => dispatch(action(connection, dispatch, getState))
      return dispatch({type: 'REGISTER_CHANNEL_CONNECT_ACTION', payload: { channel_name, action: wrapped_action }})
    } else {
      return dispatch(action(connection, dispatch, getState))
    }
  }
}

export function setupActionCable(connectionDefaults={}) {
  return {
    middleware: actionCableMiddleware,
    reducers: { connections: createReducer(connectionDefaults) }
  }
}

export function registerChannel(channel_name, identifier) {
  if (typeof identifier == 'object') {
    identifier['channel'] = identifier['channel'] || channel_name
  }
  return {
    type: 'REGISTER_CHANNEL_CONNECTION',
    payload: {
      channel_name,
      identifier,
    }
  }
}
