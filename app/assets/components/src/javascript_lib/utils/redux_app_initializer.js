/*eslint no-undef: "off"*/

import React from 'react';
import { Provider } from 'react-redux';
import { persistStore } from 'redux-persist';
import window from 'window-or-global';

import renderToDom from 'javascript_lib/utils/render_to_dom';
import createReduxStore from 'javascript_lib/utils/create_redux_store';


global.Promise = require('bluebird');


function renderApp(RootComponent, parentContainerId, reducers, reduxPersistorConfig, routes, routerReducerKey, resetActionType) {
  const store = createReduxStore(reducers, routes, resetActionType, routerReducerKey);

  renderToDom(
    (
      <Provider
        store={store}
        persistor={persistStore(store, reduxPersistorConfig)}
      >
        <RootComponent reactPackParams={window.react_pack_params}/>
      </Provider>
    ),
    parentContainerId
  );
}

export default function reduxAppInitializer(RootComponent, parentContainerId, reducers, reduxPersistorConfig, routes, routerReducerKey, resetActionType) {
  window.onload = renderApp(RootComponent, parentContainerId, reducers, reduxPersistorConfig, routes, routerReducerKey, resetActionType);
}
