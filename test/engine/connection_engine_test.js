/* eslint-disable no-undef */
let testData = require('../data/application');
let assert  = require('chai').assert;
let enableDebugOutput;
const connectionEngine = require('../../app/engines/connection');
const config = require('../../config/config');

describe('1 connection engine', function() {
  this.timeout(500000);

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
  
  it('1.1.1 getConnectionList. Type mismatch `sortOrder`', async () => {
    try {
      await connectionEngine.getConnectionList();
      assert.equal(1, 2);
    }
    catch(e) {
      assert.include(e.stack, 'asc');
    }
  });       
  it('1.1.2 getConnectionList. Type mismatch `perPage`', async () => {
    try {
      await connectionEngine.getConnectionList('a', 'a', 'asc', 'a');
      assert.equal(1, 2);
    }
    catch(e) {
      assert.include(e.stack, 'perPage should be a number');
    }
  });    
  it('1.1.3 getConnectionList. Type mismatch `page`', async () => {
    try {
      await connectionEngine.getConnectionList('a', 'a', 'asc', 1);
      assert.equal(1, 2);
    }
    catch(e) {
      assert.include(e.stack, 'page should be a number');
    }
  });      

  it('1.2.1 getConnection. Type mismatch `connectionId`', async () => {
    try {
      await connectionEngine.getConnection('a');
      assert.equal(1, 2);
    }
    catch(e) {
      assert.include(e.stack, 'connectionId should be a number');
    }
  });     

  it('1.3.1 createConnection. Type mismatch `connection`', async () => {
    try {
      await connectionEngine.createConnection(1);
    }
    catch(e) {
      assert.include(e.stack, 'connection should be an object');
    }
  });     
  it('1.3.2 createConnection. Type mismatch `createdBy`', async () => {
    try {
      await connectionEngine.createConnection({}, 1);
    }
    catch(e) {
      assert.include(e.stack, 'createdBy should be a string');
    }
  });    

  it('1.4.1 updateConnection. Type mismatch `connectionId`', async () => {
    try {
      await connectionEngine.updateConnection('a');      
    }
    catch(e) {
      assert.include(e.stack, 'connectionId should be a number');
    }
  }); 
  it('1.4.2 updateConnection. Type mismatch `connection`', async () => {
    try {
      await connectionEngine.updateConnection(1, 'a');      
    }
    catch(e) {
      assert.include(e.stack, 'connection should be an object');
    }
  }); 
  it('1.4.3 updateConnection. Type mismatch `updatedBy`', async () => {
    try {
      await connectionEngine.updateConnection(1, {}, 1);      
    }
    catch(e) {
      assert.include(e.stack, 'updatedBy should be a string');
    }
  });    

  it('1.5.1 updateConnection. Type mismatch `connectionId`', async () => {
    try {
      await connectionEngine.deleteConnection('a');      
    }
    catch(e) {
      assert.include(e.stack, 'connectionId should be a number');
    }
  }); 
  it('1.5.2 updateConnection. Type mismatch `deletedBy`', async () => {
    try {
      await connectionEngine.deleteConnection(1, 1);      
    }
    catch(e) {
      assert.include(e.stack, 'deletedBy should be a string');
    }
  }); 
});
