/* eslint-disable no-undef */
let job;
let assert  = require('chai').assert;
let sinon = require('sinon');
let enableDebugOutput;
let log = require('../../log/dispatcher');
const jobEngine = require('../../app/engines/job');
const { nanoid } = require("nanoid");
const testHelper = require('../test_helper')
const connectionEngine = require('../../app/engines/connection');
const stepEngine = require('../../app/engines/step');
const schedulator = require('schedulator');
const testData = require('../test_data');
const config = require('../../config/config');
const labels = require('../../config/message_labels')('en');
const main = require('../../app/engines/main');
const dbclient = require("../../app/tools/db");

describe('1 job engine', function() {
  this.timeout(100000);

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

  it('1.1.1 normalizeStepList. Success 1', (done) => {
    let testListData = JSON.parse(JSON.stringify(testData.stepList));
    let stepCount = testListData.length;
    jobEngine.normalizeStepList(testListData);
    assert.equal(stepCount, testListData.length);
    assert.equal(testListData[stepCount - 1].order, testListData.length);
    assert.equal(testListData[0].order, 1);
    done();
  });  
  
  it('1.1.2 normalizeStepList. Success 2', (done) => {
    let testListData = [{order: 1}, {order: 1}];
    let stepCount = testListData.length;
    jobEngine.normalizeStepList(testListData);
    assert.equal(stepCount, testListData.length);
    assert.equal(testListData[stepCount - 1].order, testListData.length);
    assert.equal(testListData[0].order, 1);
    done();
  });      
  
  it('1.1.3 normalizeStepList. stepList should have type Array', (done) => {
    assert.throws(jobEngine.normalizeStepList, 'stepList should have type Array');
    done();
  });    
  
  it('1.1.4 normalizeStepList. All step objects in the list should have order property', (done) => {
    let testListData = JSON.parse(JSON.stringify(testData.stepList));
    testListData[0] = 1;
    assert.throws(() => { jobEngine.normalizeStepList(testListData); }, `All 'step' objects in the list should have 'order' property`);
    done();
  });   
  
  it('1.2.1 getJobList. Type mismatch `sortOrder`', async () => {
    try {
      await jobEngine.getJobList('a', 'a', 'a');
    }
    catch(e) {
      assert.include(e.stack, 'asc');
    }
  });       
  it('1.2.2 getJobList. Type mismatch `perPage`', async () => {
    try {
      await jobEngine.getJobList('a', 'a', 'asc', 'a');
    }
    catch(e) {
      assert.include(e.stack, 'perPage should be a number');
    }
  });    
  it('1.2.3 getJobList. Type mismatch `page`', async () => {
    try {
      await jobEngine.getJobList('a', 'a', 'asc', 1, 'a');
    }
    catch(e) {
      assert.include(e.stack, 'page should be a number');
    }
  });   

  it('1.3.1 getJob. Type mismatch `jobId`', async () => {
    try {
      await jobEngine.getJob('a');
    }
    catch(e) {
      assert.include(e.stack, 'jobId should be a number');
    }
  });     

  it('1.4.1 createJob. Type mismatch `job`', async () => {
    try {
      await jobEngine.createJob('a');
    }
    catch(e) {
      assert.include(e.stack, 'job should be an object');
    }
  });      
  it('1.4.2 createJob. Type mismatch `createdBy`', async () => {
    try {
      await jobEngine.createJob({}, 1);
    }
    catch(e) {
      assert.include(e.stack, 'createdBy should be a string');
    }
  });      

  it('1.5.1 updateJob. Type mismatch `jobId`', async () => {
    try {
      await jobEngine.updateJob('a');
    }
    catch(e) {
      assert.include(e.stack, 'jobId should be a number');
    }
  });     
  it('1.5.2 updateJob. Type mismatch `job`', async () => {
    try {
      await jobEngine.updateJob(1, 'a');
    }
    catch(e) {
      assert.include(e.stack, 'job should be an object');
    }
  });      
  it('1.5.3 updateJob. Type mismatch `updatedBy`', async () => {
    try {
      await jobEngine.updateJob(1, {}, 1);
    }
    catch(e) {
      assert.include(e.stack, 'updatedBy should be a string');
    }
  });  

  it('1.6.1 deleteJob. Type mismatch `jobId`', async () => {
    try {
      await jobEngine.deleteJob('a');
    }
    catch(e) {
      assert.include(e.stack, 'jobId should be a number');
    }
  });       
  it('1.6.2 deleteJob. Type mismatch `deletedBy`', async () => {
    try {
      await jobEngine.deleteJob(1, 1);
    }
    catch(e) {
      assert.include(e.stack, 'deletedBy should be a string');
    }
  }); 

  it('1.7 calculateNextRun. Type mismatch `job`', async () => {
    try {
      await jobEngine.calculateNextRun('a');
    }
    catch(e) {
      assert.include(e.stack, 'job should be an object');
    }
  });   

  it('1.7.1 calculateNextRun. No `name` for schedule', async () => {
    let testJob  = JSON.parse(JSON.stringify(testData.jobOK));    
    testJob.schedules =
    [
      {
        enabled: true,
        startDateTime: '2018-01-31T20:54:23.071Z',
        eachNWeek: '1',
        dayOfWeek: ['mon', 'wed', 'fri'],
        dailyFrequency: { occursOnceAt: '11:11:11'}
      }
    ];
    let result = await jobEngine.calculateNextRun(testJob);
    assert.include(result.errorList, labels.schedule.scheduleNoName);
  });   

  it('1.8.1 updateJobNextRun. Type mismatch `jobId`', async () => {
    try {
      await jobEngine.updateJobNextRun('a');
    }
    catch(e) {
      assert.include(e.stack, 'jobId should be a number');
    }
  });     
  it('1.8.2 updateJobNextRun. Type mismatch `nextRun`', async () => {
    try {
      await jobEngine.updateJobNextRun(1, 'a');
    }
    catch(e) {
      assert.include(e.stack, 'nextRun should be a date');
    }
  });      

  it('1.9.1 updateJobLastRun. Type mismatch `jobId`', async () => {
    try {
      await jobEngine.updateJobLastRun('a');
    }
    catch(e) {
      assert.include(e.stack, 'jobId should be a number');
    }
  });     
  it('1.9.2 updateJobLastRun. Type mismatch `runResult`', async () => {
    try {
      await jobEngine.updateJobLastRun(1, 'a');
    }
    catch(e) {
      assert.include(e.stack, 'runResult should be boolean');
    }
  });      

  it('1.10.1 updateJobStatus. Type mismatch `jobId`', async () => {
    try {
      await jobEngine.updateJobStatus('a');
    }
    catch(e) {
      assert.include(e.stack, 'jobId should be a number');
    }
  });     
  it('1.10.2 updateJobStatus. Type mismatch `status`', async () => {
    try {
      await jobEngine.updateJobStatus(1, 'a');
    }
    catch(e) {
      assert.include(e.stack, 'status should be 1 or 2');
    }
  });       

  it('1.11.1 logJobHistory. Type mismatch `jobId`', async () => {
    try {
      await jobEngine.logJobHistory('a', 'a');
    }
    catch(e) {
      assert.include(e.stack, 'jobId should be a number');
    }
  });          
  it('1.11.1 logJobHistory. Type mismatch `createdBy`', async () => {
    try {
      await jobEngine.logJobHistory('a', 1, 1);
    }
    catch(e) {
      assert.include(e.stack, 'createdBy should be a string');
    }
  });   

  it('1.12.1 executeJob. Type mismatch `jobRecord`', async () => {
    try {
      await jobEngine.executeJob(undefined);
    }
    catch(e) {
      assert.include(e.stack, 'Failed to get job');
    }
  });          
  it('1.12.2 executeJob. Type mismatch `executedBy`', async () => {
    let stub = sinon.stub(jobEngine, 'updateJobStatus').returns(true);
    
    try {
      await jobEngine.executeJob('a', 1);
    }
    catch(e) {
      assert.include(e.stack, 'executedBy should be a string');
    }
    finally {
      stub.restore();
    }
  });   

  it('1.13.1 execute. Step 1 success, quitWithSuccess', async () => {
    let stub = sinon.stub(stepEngine, 'execute').resolves({ result: true, rowsAffected: 1 });
    try {
      let quitWithSuccessJob = JSON.parse(JSON.stringify(job));
      quitWithSuccessJob.job.steps[0].onSucceed = 'quitWithSuccess';
      await jobEngine.executeJob(quitWithSuccessJob, config.testUser);
      let jobRecord = (await jobEngine.getJob(quitWithSuccessJob.id));
      assert.isTrue(jobRecord.lastRunResult);
    }
    finally {
      stub.restore();
    }
  });  

  it('1.13.2 execute. Step 1 success, quitWithFailure', async () => {
    let stub = sinon.stub(stepEngine, 'execute').resolves({ result: true, rowsAffected: 1 });
    try {
      let quitWithFailureJob = JSON.parse(JSON.stringify(job));
      quitWithFailureJob.job.steps[0].onSucceed = 'quitWithFailure';
      await jobEngine.executeJob(quitWithFailureJob, config.testUser);
      let jobRecord = (await jobEngine.getJob(quitWithFailureJob.id));
      assert.isFalse(jobRecord.lastRunResult);
    }
    finally {
      stub.restore();
    }
  });  

  it('1.13.3 execute. Step 1 success, gotoNextStep, failed to repeat step 2, quitWithFailure finally', async () => {
    let stub1 = sinon.stub(stepEngine, 'execute').resolves({ result: false, error: 'execute_error' });
    stub1.onFirstCall().resolves({ result: true, rowsAffected: 1 });
    let stub2 = sinon.stub(stepEngine, 'delayedExecute').resolves({ result: false, error: 'attemp_error' });
    try {
      await jobEngine.executeJob(job, config.testUser);
      let jobRecord = (await jobEngine.getJob(job.id));
      assert.isFalse(jobRecord.lastRunResult);
    }
    finally {
      stub1.restore();
      stub2.restore();
    }
  });

  it('1.13.4 execute. Step 1 success, gotoNextStep, failed to repeat step 2, quitWithSuccess finally', async () => {
    let stub1 = sinon.stub(stepEngine, 'execute').resolves({ result: false, error: 'execute_error' });
    stub1.onFirstCall().resolves({ result: true, rowsAffected: 1 });
    let stub2 = sinon.stub(stepEngine, 'delayedExecute').resolves({ result: false, error: 'attemp_error' });
    try {
      let quitWithSuccessJob = JSON.parse(JSON.stringify(job));
      quitWithSuccessJob.job.steps[1].onFailure = 'quitWithSuccess';
      await jobEngine.executeJob(quitWithSuccessJob, config.testUser);
      let jobRecord = (await jobEngine.getJob(quitWithSuccessJob.id));
      assert.isTrue(jobRecord.lastRunResult);
    }
    finally {
      stub1.restore();
      stub2.restore();
    }
  });   

  it('1.13.5 execute. Step 1 success, gotoNextStep, failed to repeat step 2, gotoNextStep finally', async () => {
    let stub1 = sinon.stub(stepEngine, 'execute').resolves({ result: false, error: 'execute_error' });
    stub1.onFirstCall().resolves({ result: true, rowsAffected: 1 });
    let stub2 = sinon.stub(stepEngine, 'delayedExecute').resolves({ result: false, error: 'attemp_error'});
    
    try {
      let gotoNextStepJob = JSON.parse(JSON.stringify(job));
      gotoNextStepJob.job.steps[1].onFailure = 'gotoNextStep';
      await jobEngine.executeJob(gotoNextStepJob, config.testUser);
      let jobRecord = (await jobEngine.getJob(gotoNextStepJob.id));
      assert.isTrue(jobRecord.lastRunResult);
    }
    finally {
      stub1.restore();
      stub2.restore();
    }
  });   

  it('1.13.6 execute. Step 1 success, gotoNextStep, success on repeating, gotoNextStep finally', async () => {
    let stub1 = sinon.stub(stepEngine, 'execute').resolves({ result: false, error: 'execute_error' });
    stub1.onFirstCall().resolves({ result: true, rowsAffected: 1 });     
    let stub2 = sinon.stub(stepEngine, 'delayedExecute').resolves({ result: true, rowsAffected: 1 });
    try {
      let gotoNextStepJob = JSON.parse(JSON.stringify(job));
      gotoNextStepJob.job.steps[1].onSucceed = 'gotoNextStep';
      await jobEngine.executeJob(gotoNextStepJob, config.testUser);
      let jobRecord = (await jobEngine.getJob(gotoNextStepJob.id));
      assert.isTrue(jobRecord.lastRunResult);

    }
    finally {
      stub1.restore();
      stub2.restore();
    }
  });   

  it('1.13.7 execute. Step 1 success, gotoNextStep, success on repeating, quitWithSuccess finally', async () => {
    let stub1 = sinon.stub(stepEngine, 'execute').resolves({ result: false, error: 'execute_error' });
    stub1.onFirstCall().resolves({ result: true, rowsAffected: 1 });     
    let stub2 = sinon.stub(stepEngine, 'delayedExecute').resolves({ result: true, rowsAffected: 1 });
    try {
      let quitWithSuccessJob = JSON.parse(JSON.stringify(job));
      quitWithSuccessJob.job.steps[1].onSucceed = 'quitWithSuccess';
      await jobEngine.executeJob(quitWithSuccessJob, config.testUser);
      let jobRecord = (await jobEngine.getJob(quitWithSuccessJob.id));
      assert.isTrue(jobRecord.lastRunResult);
    }
    finally {
      stub1.restore();
      stub2.restore();
    }
  });

  it('1.13.8 execute. Step 1 success, gotoNextStep, success on repeating, quitWithFailure finally', async () => {
    let stub1 = sinon.stub(stepEngine, 'execute').resolves({ result: false, error: 'execute_error' });
    stub1.onFirstCall().resolves({ result: true, rowsAffected: 1 });   
    let stub2 = sinon.stub(stepEngine, 'delayedExecute').resolves({ result: true, rowsAffected: 1 });
    try {
      let quitWithFailureJob = JSON.parse(JSON.stringify(job));
      quitWithFailureJob.job.steps[1].onSucceed = 'quitWithFailure';
      await jobEngine.executeJob(quitWithFailureJob, config.testUser);
      let jobRecord = (await jobEngine.getJob(quitWithFailureJob.id));
      assert.isFalse(jobRecord.lastRunResult);
    }
    finally {
      stub1.restore();
      stub2.restore();
    }
  });

  it('1.13.9 execute. Step list is empty', async () => {
    let spy = sinon.spy(log, 'info');
    try {   
      let noStepJob = JSON.parse(JSON.stringify(job));
      noStepJob.job.steps = [];    
      await jobEngine.executeJob(noStepJob, config.testUser);
      assert.include(spy.args[1][0], 'No any steps were found');
    } finally {
      spy.restore();
    }
  });

  it('1.13.10 execute. Failed to get job', async () => {
    let spy = sinon.spy(log, 'error');
    try {
      await jobEngine.executeJob();
      assert.include(spy.args[0][0], 'Failed to get job');
    }
    finally {
      spy.restore();
    }
  });

  it('1.13.11 execute. Failed to calculate next run', async () => {
    let stub1 = sinon.stub(stepEngine, 'execute').resolves({ result: false, error: 'execute_error' });
    stub1.onFirstCall().resolves({ result: true, rowsAffected: 1 });       
    let stub2 = sinon.stub(stepEngine, 'delayedExecute').resolves({ result: true, rowsAffected: 1 });
    try {
      let failedJob = JSON.parse(JSON.stringify(job));
      failedJob.job.schedules = [];
      failedJob = await jobEngine.createJob(failedJob.job, config.testUser);  
      await jobEngine.executeJob(failedJob, config.testUser);
      let jobRecord = (await jobEngine.getJob(failedJob.id));
      assert.isNull(jobRecord.nextRun);
    }
    finally {
      stub1.restore();
      stub2.restore();
    }
  });

  it('1.14.1 calculateNextRun. Failed to validate schedule', (done) => {
    let job = JSON.parse(JSON.stringify(testData.jobOK));
    job.schedules[0].fail = true;
    let result = jobEngine.calculateNextRun(job);
    assert.isFalse(result.isValid);
    done();
  });       

  it('1.14.2 calculateNextRun. Failed to calculate next run', (done) => {
    let job = JSON.parse(JSON.stringify(testData.jobOK));
    let stub = sinon.stub(schedulator, 'nextOccurrence').returns({ result: null, error: 'dummy'});

    let result = jobEngine.calculateNextRun(job);
    assert.isFalse(result.isValid);
    stub.restore();
    done();
  });        

  it('1.15.1 3-minutes execution test. Create connection, create 21 jobs, wait 3 minutes, check if records were created in DB', async () => {    

    let numberOfJobs = 20;
    let minutes = 3;

    let connection = await connectionEngine.createConnection(testData.execution.connection, config.testUser);

    let uid = nanoid();
    
    for (let index = 0; index < numberOfJobs; index++) {
      let job = JSON.parse(JSON.stringify(testData.execution.job));
      job.name = `Execution test job ${index}`;      
      job.steps[0].command = job.steps[0].command.replace('insert_value', `Potatoe${index}-${uid}`);
      job.steps[0].connection = connection.id;
      await jobEngine.createJob(job, config.testUser);   
    }
    //Run execution loop for {minutes} minutes
    //Main loop
    console.log(`🚀 Starting execution loop at ${Date()}, test sleep for ${minutes} minutes...`)
    let t = setInterval(main.run, 1000, config.runTolerance);    
    //Startup actions
    await main.updateOverdueJobs();
    await main.resetAllJobsStatuses();   
    //Run loop for 5 minutes
    await new Promise(resolve => setTimeout(resolve, 60000*minutes));    
    console.log(`🚀 Finishing execution loop at ${Date()}`)
    clearInterval(t);
    let rowCount = await new Promise((resolve, reject) => {
      const query = {
        "text": `SELECT count(id) FROM public."sysAbyss" where "text" like '%${uid}%'`
      };
      dbclient.query(query, (err, result) => {  
        if(result.rows)
          resolve(result.rows[0].count);
        else
          reject(0);
      });
    });

    assert.equal(rowCount, numberOfJobs*3)

  }).timeout(305000);;        
  
});
