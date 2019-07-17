let objectId = 426;
const jobEngine = require('../../app/engines/job');

describe('job engine', function() {
    it('execute job', (done) => {
        jobEngine.executeJob(objectId, 'testBot')
        done();
    });                                          
});
