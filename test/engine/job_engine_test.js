/* eslint-disable no-undef */
let job;
let testData = require('../test_data');
let assert  = require('chai').assert;
let sinon = require('sinon');
let enableDebugOutput;
const jobEngine = require('../../app/engines/job');
const jobTestObject = require('../test_data').jobOK;
const config = require('../../config/config');
const dbclient = require('../../app/tools/db');

describe.only('1 job engine', function() {
  before(async () => {
    //temporary disable debug output due to have clear test output
    enableDebugOutput = config.enableDebugOutput;
    config.enableDebugOutput = false;    
    job = await jobEngine.createJob(testData.jobOK, config.testUser);    
  }); 

  after(() => {
    //restore initial debug output
    config.enableDebugOutput = enableDebugOutput;
  });
  
  it('1.2 getJobList. DB failure', async () => {
    try {
      await jobEngine.getJobList('', '', '', 'a', 'a');
    }
    catch(e) {
      assert.include(e.stack, 'Error');
    }
  });       

  it('1.3 getJob. DB failure', async () => {
    try {
      await jobEngine.getJob('a');
    }
    catch(e) {
      assert.include(e.stack, 'Error');
    }
  });     

  it('1.4 createJob. DB failure', async () => {
    try {
      await jobEngine.createJob();
    }
    catch(e) {
      assert.include(e.stack, 'Error');
    }
  });     

  it('1.5.1 updateJob. toUTCString() failure', async () => {
    try {
      await jobEngine.updateJob();      
    }
    catch(e) {
      assert.include(e.stack, 'Error');
    }
  });   

  it('1.5.2 updateJob. DB failure', async () => {
    try {
      await jobEngine.updateJob('a', {nextRun: new Date()});      
    }
    catch(e) {
      assert.include(e.stack, 'Error');
    }
  }); 

  it('1.6 deleteJob. DB failure', async () => {
    try {
      await jobEngine.deleteJob('s');
    }
    catch(e) {
      assert.include(e.stack, 'Error');
    }
  });   

  it('1.7 updateJobNextRun. DB failure', async () => {
    try {
      await jobEngine.updateJobNextRun('a');
    }
    catch(e) {
      assert.include(e.stack, 'Error');
    }
  });   

  it('1.8 updateJobLastRun. DB failure', async () => {
    try {
      await jobEngine.updateJobLastRun('a');
    }
    catch(e) {
      assert.include(e.stack, 'Error');
    }
  });    

  it('1.9 updateJobStatus. DB failure', async () => {
    try {
      await jobEngine.updateJobStatus('a');
    }
    catch(e) {
      assert.include(e.stack, 'Error');
    }
  });    

  it('1.10 logJobHistory. DB failure', async () => {
    try {
      await jobEngine.logJobHistory('a', 'a');
    }
    catch(e) {
      assert.include(e.stack, 'Error');
    }
  });  


  it('1.11 execute', async () => {
    //TODO
  });  

  it('1.99 calculateNextRun. Failed to validate schedule', (done) => {
    let job = JSON.parse(JSON.stringify(jobTestObject));
    job.schedules[0].fail = true;
    let result = jobEngine.calculateNextRun(job);
    assert.isFalse(result.isValid);
    done();
  });       
});
