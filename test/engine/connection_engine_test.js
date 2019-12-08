/* eslint-disable no-undef */
let testData = require('../test_data');
let assert  = require('chai').assert;
let enableDebugOutput;
const connectionEngine = require('../../app/engines/connection');
const config = require('../../config/config');

describe('1 connection engine', function() {
  this.timeout(100000);

  before(async () => {
    //temporary disable debug output due to have clear test output
    enableDebugOutput = config.enableDebugOutput;
    config.enableDebugOutput = false;    
    connection = await connectionEngine.createConnection(testData.connectionOK, config.testUser);    
  }); 

  after(() => {
    //restore initial debug output
    config.enableDebugOutput = enableDebugOutput;
  });
  
  it('1.2 getConnectionList. DB failure', async () => {
    try {
      await connectionEngine.getConnectionList('', '', '', 'a', 'a');
    }
    catch(e) {
      assert.include(e.stack, 'Error');
    }
  });       

  it('1.3 getConnection. DB failure', async () => {
    try {
      await connectionEngine.getConnection('a');
    }
    catch(e) {
      assert.include(e.stack, 'Error');
    }
  });     

  it('1.4 createConnection. DB failure', async () => {
    try {
      await connectionEngine.createConnection();
    }
    catch(e) {
      assert.include(e.stack, 'Error');
    }
  });     

  it('1.5 updateConnection. DB failure', async () => {
    try {
      await connectionEngine.updateConnection('a');      
    }
    catch(e) {
      assert.include(e.stack, 'Error');
    }
  }); 

  it('1.6 deleteConnection. DB failure', async () => {
    try {
      await connectionEngine.deleteConnection('s');
    }
    catch(e) {
      assert.include(e.stack, 'Error');
    }
  });   
});
