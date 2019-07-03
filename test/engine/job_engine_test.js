let objectId = 426;
const jobEngine = require('../../app/engine/job');

describe('job engine', function() {
    //sometimes test for creation of objectId is being executed late and objectId becomes undefined
    it('execute job', (done) => {
        jobEngine.executeJob(objectId, 'testBot')
        done();
    });                                          
});
