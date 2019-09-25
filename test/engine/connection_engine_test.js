/* eslint-disable no-undef */
let objectId = 0;
const connectionEngine = require('../../app/engines/connection');
const assert  = require('chai').assert;

describe('1 connection engine', function() {
  it('1.1 execute job', (done) => {
    connectionEngine.getConnection(objectId)
      .then(resolve => { assert.isNull(resolve); done(); }, reject => { assert.isNull(reject); done(); });
  });                                          
});
