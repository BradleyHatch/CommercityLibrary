import thunk from 'redux-thunk';
import { combineReducers } from 'redux';
import { createStore, applyMiddleware, compose } from 'redux';
import { autoRehydrate } from 'redux-persist';
import { routerForBrowser } from 'redux-little-router';
import window from 'window-or-global';


const composeEnhancers = window.__REDUX_DEVTOOLS_EXTENSION_COMPOSE__ || compose;


function addResetActionReducers(reducers, routerReducer, resetActionType, routerReducerKey) {
  const allReducers = combineReducers(Object.assign({}, {[routerReducerKey]: routerReducer}, reducers));

  return (state, action) => {
    if(action.type === resetActionType) {
      state = undefined;
    }

    return allReducers(state, action);
  };
}

export default function createReduxStore(reducers, routes, resetActionType, routerReducerKey) {
  const {
    reducer,
    middleware,
    enhancer
  } = routerForBrowser({
    routes
  });
  const reducersWithReset = addResetActionReducers(reducers, reducer, resetActionType, routerReducerKey);
  const middlewares = [middleware, thunk];

  return createStore(
    reducersWithReset,
    composeEnhancers(
      enhancer,
      autoRehydrate(),
      applyMiddleware(...middlewares)
    )
  );
}
