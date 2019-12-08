/* eslint-disable no-undef */
let job;
let testData = require('../test_data');
let assert  = require('chai').assert;
let sinon = require('sinon');
let enableDebugOutput;
let log = require('../../log/dispatcher');
const jobEngine = require('../../app/engines/job');
const stepEngine = require('../../app/engines/step');
const schedulator = require('schedulator');
const jobTestObject = require('../test_data').jobOK;
const config = require('../../config/config');

describe('1 job engine', function() {
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

  it.only('1.11.1 execute. Step 1 success, quitWithSuccess', async () => {
    let quitWithSuccessJob = JSON.parse(JSON.stringify(job));
    quitWithSuccessJob.job.steps[0].onSucceed = 'quitWithSuccess';
    await jobEngine.executeJob(quitWithSuccessJob, config.testUser);
    let jobRecord = (await jobEngine.getJob(quitWithSuccessJob.id));
    assert.isTrue(jobRecord.lastRunResult);

  }).timeout(10000);  

  it('1.11.2 execute. Step 1 success, quitWithFailure', async () => {
    let quitWithFailureJob = JSON.parse(JSON.stringify(job));
    quitWithFailureJob.job.steps[0].onSucceed = 'quitWithFailure';
    await jobEngine.executeJob(quitWithFailureJob, config.testUser);
    let jobRecord = (await jobEngine.getJob(quitWithFailureJob.id));
    assert.isFalse(jobRecord.lastRunResult);
  });  

  it('1.11.3 execute. Step 1 success, gotoNextStep, failed to repeat step 2, quitWithFailure finally', async () => {
    let stub = sinon.stub(stepEngine, 'delayedExecute').resolves({ result: false, error: 'attemp_error' });

    await jobEngine.executeJob(job, config.testUser);
    let jobRecord = (await jobEngine.getJob(job.id));
    assert.isFalse(jobRecord.lastRunResult);

    stub.restore();
  });

  it('1.11.4 execute. Step 1 success, gotoNextStep, failed to repeat step 2, quitWithSuccess finally', async () => {
    let stub = sinon.stub(stepEngine, 'delayedExecute').resolves({ result: false, error: 'attemp_error' });

    let quitWithSuccessJob = JSON.parse(JSON.stringify(job));
    quitWithSuccessJob.job.steps[1].onFailure = 'quitWithSuccess';
    await jobEngine.executeJob(quitWithSuccessJob, config.testUser);
    let jobRecord = (await jobEngine.getJob(quitWithSuccessJob.id));
    assert.isTrue(jobRecord.lastRunResult);

    stub.restore();
  });   

  it('1.11.5 execute. Step 1 success, gotoNextStep, failed to repeat step 2, gotoNextStep finally', async () => {
    let stub = sinon.stub(stepEngine, 'delayedExecute').resolves({ result: false, error: 'attemp_error' });
    
    let gotoNextStepJob = JSON.parse(JSON.stringify(job));
    gotoNextStepJob.job.steps[1].onFailure = 'gotoNextStep';
    await jobEngine.executeJob(gotoNextStepJob, config.testUser);
    let jobRecord = (await jobEngine.getJob(gotoNextStepJob.id));
    assert.isTrue(jobRecord.lastRunResult);

    stub.restore();
  });   

  it('1.11.6 execute. Step 1 success, gotoNextStep, success on repeating, gotoNextStep finally', async () => {
    let stub = sinon.stub(stepEngine, 'delayedExecute').resolves({ result: true, rowsAffected: 1 });
    
    let gotoNextStepJob = JSON.parse(JSON.stringify(job));
    gotoNextStepJob.job.steps[1].onSucceed = 'gotoNextStep';
    await jobEngine.executeJob(gotoNextStepJob, config.testUser);
    let jobRecord = (await jobEngine.getJob(gotoNextStepJob.id));
    assert.isTrue(jobRecord.lastRunResult);

    stub.restore();
  });   

  it('1.11.7 execute. Step 1 success, gotoNextStep, success on repeating, quitWithSuccess finally', async () => {
    let stub = sinon.stub(stepEngine, 'delayedExecute').resolves({ result: true, rowsAffected: 1 });
    
    let quitWithSuccessJob = JSON.parse(JSON.stringify(job));
    quitWithSuccessJob.job.steps[1].onSucceed = 'quitWithSuccess';
    await jobEngine.executeJob(quitWithSuccessJob, config.testUser);
    let jobRecord = (await jobEngine.getJob(quitWithSuccessJob.id));
    assert.isTrue(jobRecord.lastRunResult);

    stub.restore();
  });

  it('1.11.8 execute. Step 1 success, gotoNextStep, success on repeating, quitWithFailure finally', async () => {
    let stub = sinon.stub(stepEngine, 'delayedExecute').resolves({ result: true, rowsAffected: 1 });
    
    let quitWithFailureJob = JSON.parse(JSON.stringify(job));
    quitWithFailureJob.job.steps[1].onSucceed = 'quitWithFailure';
    await jobEngine.executeJob(quitWithFailureJob, config.testUser);
    let jobRecord = (await jobEngine.getJob(quitWithFailureJob.id));
    assert.isFalse(jobRecord.lastRunResult);

    stub.restore();
  });

  it('1.11.9 execute. Step list is empty', async () => {
   
    let noStepJob = JSON.parse(JSON.stringify(job));
    noStepJob.job.steps = [];
    let spy = sinon.spy(log, 'warn');
    await jobEngine.executeJob(noStepJob, config.testUser);

    assert.include(spy.args[0][0], 'No step list found');
    spy.restore();
  });

  it('1.11.10 execute. Failed to get job', async () => {
    let spy = sinon.spy(log, 'error');
    await jobEngine.executeJob();

    assert.include(spy.args[0][0], 'Failed to get job');
    spy.restore();
  });

  it('1.11.11 execute. Failed to calculate next run', async () => {
    let stub = sinon.stub(stepEngine, 'delayedExecute').resolves({ result: false, error: 'attemp_error' });
    let failedJob = JSON.parse(JSON.stringify(job));
    failedJob.job.schedules = [];
    await jobEngine.executeJob(failedJob, config.testUser);
    let jobRecord = (await jobEngine.getJob(failedJob.id));
    assert.isNull(jobRecord.nextRun);
    stub.restore();
  });

  it('1.12.1 calculateNextRun. Failed to validate schedule', (done) => {
    let job = JSON.parse(JSON.stringify(jobTestObject));
    job.schedules[0].fail = true;
    let result = jobEngine.calculateNextRun(job);
    assert.isFalse(result.isValid);
    done();
  });       

  it('1.12.2 calculateNextRun. Failed to calculate next run', (done) => {
    let job = JSON.parse(JSON.stringify(jobTestObject));
    let stub = sinon.stub(schedulator, 'nextOccurrence').returns({ result: null, error: 'dummy'});

    let result = jobEngine.calculateNextRun(job);
    assert.isFalse(result.isValid);
    stub.restore();
    done();
  });        
});
