import { combineReducers, applyMiddleware, createStore } from "redux"
import thunk from "redux-thunk"
import { createLogger } from "redux-logger"

import reducers from "reducers/index"

import {setupActionCable} from 'utils/action_cable'


const { middleware: action_middleware, reducers: action_reducers } = setupActionCable()

const allReducers = combineReducers({
  ...reducers,
  ...action_reducers,
})


const middleware = applyMiddleware(action_middleware, thunk, createLogger())

export default createStore(allReducers, middleware)
