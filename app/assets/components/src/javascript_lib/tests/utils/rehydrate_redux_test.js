import test from 'tape';

import { REHYDRATE } from 'redux-persist/constants'

import rehydrateRedux from 'javascript_lib/utils/rehydrate_redux';


const REDUCER_TEST_KEY = "TEST";

const STATE = {
  test: "testTest"
};
const REHYDRATED_STATE = {
  test2: "test2"
};

const NON_REHYDRATE_ACTION = {
  type: "test",
  payload: {
    [REDUCER_TEST_KEY]: {
      test2: "test2"
    }
  }
};

const REHYDRATE_ACTION = {
  type: REHYDRATE,
  payload: {
    [REDUCER_TEST_KEY]: {
      test2: "test2"
    }
  }
};


test("rehydrate_redux", function(t) {
  t.deepEqual(
    rehydrateRedux(STATE, NON_REHYDRATE_ACTION, REDUCER_TEST_KEY),
    STATE,
    "(type !== REHYDRATE) then the passed state will be returned"
  );

  t.deepEqual(
    rehydrateRedux(REHYDRATED_STATE, REHYDRATE_ACTION, REDUCER_TEST_KEY, true),
    REHYDRATED_STATE,
    "(type === REHYDRATE) the state for that reducer key is returned"
  );


  t.end();
});
