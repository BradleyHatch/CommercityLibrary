import test from 'tape';
import Actual from 'actual';

import {
  getDeviceDimensions
} from 'javascript_lib/utils/media_break_point_utils'


test("media_break_point_utils - getDeviceDimensions", function (t) {
  t.deepEqual(
    getDeviceDimensions(),
    {
      width: Actual("width", "px"),
      height: Actual("height", "px")
    },
    "device dimensions values are correct"
  );


  t.end();
});
