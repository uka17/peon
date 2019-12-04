/* eslint-disable no-undef */
let objectId;
let testData = require('../test_data');
let config = require('../../config/config');
let assert  = require('chai').assert;
const jobEngine = require('../../app/engines/job');
/*
describe('1 job engine', function() {
  
  before(async () => {
    objectId = await jobEngine.createJob(testData.jobOK, config.testUser);
  }); 

  it('1.1 execute job', (done) => {
    jobEngine.executeJob(objectId, config.testUser);
    done();
  });                                          
});
*/