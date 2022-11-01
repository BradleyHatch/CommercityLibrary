import { REHYDRATE } from 'redux-persist/constants';


export default function rehydrateRedux(state, action, reducerKey) {
  if (action.type === REHYDRATE) {
    const persistedState = action.payload[reducerKey];

    if(persistedState != null) {
      return persistedState;
    }
  }

  return state;
}
