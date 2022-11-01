
export default function(connection_defaults={}) {

  //  [channel_name]: {
  //    identifier: channel_identifier
  //    connection: SUBSCRIPTION_OBJECT
  // '  connected': false
  //    on_connect_actions: []

  const initialState = Object.keys(connection_defaults).reduce((initialState, channelName)=>{
    initialState[channelName] = {
      identifier: connection_defaults[channelName]
    }
    return initialState;
  }, {})

  return function(state=initialState, action) {
    if (action.payload == undefined) return state;

    var { channel_name } = action.payload

    switch (action.type) {
      case 'REGISTER_CHANNEL_CONNECTION':
        return {...state, [channel_name]: {
          ...state[channel_name],
          identifier: action.payload.identifier,
        }};
      case 'CONNECT_CHANNEL':
        return {...state, [channel_name]: {
          ...state[channel_name],
          connection: action.payload.connection,
          connected: false,
          on_connect_actions: [],
        }};
      case 'CONNECTION_ESTABLISHED':
        return {...state, [channel_name]: {
          ...state[channel_name],
          connected: true,
        }};
      case 'CONNECTION_DROPPED':
        return {...state, [channel_name]: {
          ...state[channel_name],
          connected: false,
        }};
      case 'REGISTER_CHANNEL_CONNECT_ACTION':
        return {...state, [channel_name]: {
          ...state[channel_name],
          on_connect_actions: [...state[channel_name].on_connect_actions, action.payload.action]
        }};
      case 'CHANNEL_CONNECTION_ACTIONS_RUN':
        return {...state, [channel_name]: {
          ...state[channel_name],
          on_connect_actions: []
        }};
    }
    return state
  }
}
