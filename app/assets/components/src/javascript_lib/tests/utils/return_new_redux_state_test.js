import test from 'tape';

import returnNewReduxState from 'javascript_lib/utils/return_new_redux_state';


const STATE = {
  test: "testTest"
};

const ADD_ACTION = {
  type: "add action",
  test2: "test2"
};

const ADD_STATE = {
  test: "testTest",
  type: "add action",
  test2: "test2"
};

const REPLACE_ACTION = {
  type: "replace action",
  test: "test2"
};


test("return_new_redux_state", function(t) {
  t.deepEqual(
    returnNewReduxState(STATE, ADD_ACTION),
    ADD_STATE,
    "merges action fields into the state"
  );

  t.deepEqual(
    returnNewReduxState(STATE, REPLACE_ACTION),
    REPLACE_ACTION,
    "replaces identical state key/values with the actions payload"
  );


  t.end();
});
