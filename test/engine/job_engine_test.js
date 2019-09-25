/* eslint-disable no-undef */
let objectId = 426;
const jobEngine = require('../../app/engines/job');

describe('1 job engine', function() {
  it('1.1 execute job', (done) => {
    jobEngine.executeJob(objectId, 'testBot');
    done();
  });                                          
});
