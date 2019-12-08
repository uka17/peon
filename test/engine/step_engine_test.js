/* eslint-disable no-undef */
let testData = require('../test_data');
let config = require('../../config/config');
let assert  = require('chai').assert;
let dbclient = require('../../app/tools/db');
let connectionEngine = require('../../app/engines/connection');
let sinon = require('sinon');
const stepEngine = require('../../app/engines/step');

describe('1 step engine', function() {

  it('1.1 execute. Success', async () => {
    let stub1 = sinon.stub(dbclient, 'userQuery').resolves({rowCount: 1});
    let stub2 = sinon.stub(connectionEngine, 'getConnection').resolves({connection: true});

    try {
      let res = await stepEngine.execute({}, config.testUser);
      assert.equal(res.affected, 1);
      assert.isTrue(res.result);
    }
    finally {
      stub1.restore();
      stub2.restore();
    }
  });    

  it('1.2 execute. Success', async () => {
    let stub1 = sinon.stub(dbclient, 'userQuery').rejects({});
    let stub2 = sinon.stub(connectionEngine, 'getConnection').resolves({connection: true});

    try {
      let res = await stepEngine.execute({}, config.testUser);
      assert.isFalse(res.result);
    }
    finally {
      stub1.restore();
      stub2.restore();
    }
  });    

  it('1.3 delayedExecute. Success', async () => {
    let stub1 = sinon.stub(dbclient, 'userQuery').resolves({rowCount: 1});
    let stub2 = sinon.stub(connectionEngine, 'getConnection').resolves({connection: true});

    try {
      let res = await stepEngine.delayedExecute({}, 0.001);
      assert.equal(res.affected, 1);
      assert.isTrue(res.result);
    }
    finally {
      stub1.restore();
      stub2.restore();
    }
  });    
});
