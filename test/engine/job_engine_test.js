/* eslint-disable no-undef */
let jobId, job;
const jobEngine = require('../../app/engines/job');
const jobTestObject = require('../test_data').jobOK;
let assert  = require('chai').assert;
const config = require('../../config/config');

describe('1 job engine', function() {
  /*
  before(async () => {
    job = await jobEngine.createJob(testData.jobOK, config.testUser);
  }); 

  it('1.1 execute job', (done) => {
    jobEngine.executeJob(objectId, config.testUser);
    done();
  });      
  */
  
  it('1.2 calculateNextRun. Failed to validate schedule', (done) => {
    let job = JSON.parse(JSON.stringify(jobTestObject));
    job.schedules[0].fail = true;
    let result = jobEngine.calculateNextRun(job);
    assert.isFalse(result.isValid);
    done();
  });       
});
