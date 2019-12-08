/* eslint-disable no-undef */
let testData = require('../test_data');
let config = require('../../config/config');
let assert  = require('chai').assert;
let dbclient = require('../../app/tools/db');
let connectionEngine = require('../../app/engines/connection');
let sinon = require('sinon');
const stepEngine = require('../../app/engines/step');

describe.only('1 job engine', function() {

  it('1.1 execute. Success', async () => {
    let stub1 = sinon.stub(dbclient, 'userQuery').resolves(true);
    let stub2 = sinon.stub(connectionEngine, 'getConnection').resolves({rowCount: 1});

    try {
      let res = stepEngine.execute({}, config.testUser);
      console.log(res);
      assert.equal(res.affected, 1);
      assert.isTrue(res.result);
    }
    finally {
      stub1.restore();
      stub2.restore();
    }
  });                                          
});
