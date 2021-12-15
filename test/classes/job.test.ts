/* eslint-disable no-undef */
let job: Job;
import { assert } from "chai";
import chai from "chai";
import chaiAsPromised from "chai-as-promised";
chai.use(chaiAsPromised);
import sinon from "sinon";
let enableDebugOutput;
import LogDispatcher from "../../src/classes/logDispatcher";
import config from "../../src/config/config";
const log = LogDispatcher.getInstance(
  config.enableDebugOutput,
  config.logLevel
);
import Job, { IJob } from "../../src/classes/job";
import { nanoid } from "nanoid";
import Connection from "../../src/classes/connection";
import { SimpleStepActionType } from "../../src/classes/step";
import testData from "../data/application";
import message_labels from "../../src/config/message_labels";
const labels = message_labels("en");
import Engine from "../../src/classes/engine";
import { executeSysQuery } from "../../src/tools/db";
import ConnectionBody from "../../src/classes/connectionBody";

describe("1 job class", function () {
  this.timeout(100000);

  before(async () => {
    //temporary disable debug output due to have clear test output
    enableDebugOutput = config.enableDebugOutput;
    config.enableDebugOutput = false;
    const newJob: Job = new Job({
      body: testData.jobBodyOK,
    } as unknown as IJob);
    job = (await newJob.save(config.testUser)) as Job;
  });

  after(() => {
    //restore initial debug output
    config.enableDebugOutput = enableDebugOutput;
  });

  it("1.0.1 step list should have type Array. Fail", (done) => {
    const nslJobTemplate = JSON.parse(JSON.stringify(testData.jobBodyOK));
    nslJobTemplate.steps = "a";
    try {
      new Job({ body: nslJobTemplate } as unknown as IJob);
    } catch (e) {
      assert.include((e as Error).message, "step list should have type Array");
      done();
    }
  });

  it("1.0.2 list. Empty result", async () => {
    const res = await Job.list(nanoid());
    assert.isNull(res);
  });

  it("1.1.1 normalizeStepList. Success 1", (done) => {
    const nslJobTemplate = JSON.parse(JSON.stringify(testData.jobBodyOK));
    nslJobTemplate.steps = JSON.parse(JSON.stringify(testData.stepList));
    const nslJob = new Job({ body: nslJobTemplate } as unknown as IJob);
    const stepCount = nslJob.body.steps.length;
    nslJob.normalizeStepList();
    assert.equal(stepCount, nslJob.body.steps.length);
    assert.equal(
      nslJob.body.steps[stepCount - 1].order,
      nslJob.body.steps.length
    );
    assert.equal(nslJob.body.steps[0].order, 1);
    done();
  });

  it("1.1.2 normalizeStepList. Success 2", (done) => {
    const nslJobTemplate = JSON.parse(JSON.stringify(testData.jobBodyOK));
    nslJobTemplate.steps = [{ order: 1 }, { order: 1 }];
    const nslJob = new Job({ body: nslJobTemplate } as unknown as IJob);
    const stepCount = nslJob.body.steps.length;
    nslJob.normalizeStepList();
    assert.equal(stepCount, nslJob.body.steps.length);
    assert.equal(
      nslJob.body.steps[stepCount - 1].order,
      nslJob.body.steps.length
    );
    assert.equal(nslJob.body.steps[0].order, 1);
    done();
  });

  it("1.1.4 normalizeStepList. All step objects in the list should have order property", (done) => {
    //"Kolya poznaet JavaScript" or "JavaScript novice common mistake"... fuck... 40 minutes lost
    //Since we pass not the normalizeStepList as method of nslJob, but just function which is disconnected from context, this becomes undefined
    //In order to fix it we need to bind nslJob to this function 'this'
    const nslJobTemplate = JSON.parse(JSON.stringify(testData.jobBodyOK));
    nslJobTemplate.steps[0] = {};
    const nslJob = new Job({ body: nslJobTemplate } as unknown as IJob);
    assert.throws(
      nslJob.normalizeStepList.bind(nslJob),
      `objects in the list should have 'order' property type number`
    );
    done();
  });
  //Poher, let it be 2 types of Error assertions - one thought Promise and another one in "kolhoz-style" via exception
  it("1.2.1 list. Type mismatch `sortOrder`", async () => {
    try {
      await Job.list("a", "id", "a", 1, 10);
    } catch (e) {
      assert.include((e as unknown as Record<string, unknown>).stack, "asc");
    }
  });

  it("1.3.1 update. Job not saved", async () => {
    const uJob = new Job({
      body: JSON.parse(JSON.stringify(testData.jobBodyOK)),
    } as unknown as IJob);
    return assert.isRejected(
      uJob.update(config.testUser),
      `save it before any changes`
    );
  });

  it("1.4.1 delete. Job not saved", async () => {
    const dJob = new Job({
      body: JSON.parse(JSON.stringify(testData.jobBodyOK)),
    });
    return assert.isRejected(
      dJob.delete(config.testUser),
      `Job was not changed at database level, save it before any changes`
    );
  });

  it("1.5.1 calculateNextRun. Job not composed properly", async () => {
    try {
      const dJob = new Job();
      dJob.calculateNextRun();
    } catch (e) {
      assert.include(
        (e as unknown as Record<string, unknown>).stack,
        "not composed properly"
      );
    }
  });

  it("1.5.2 calculateNextRun. No `name` for schedule", async () => {
    const testJob = new Job({
      body: JSON.parse(JSON.stringify(testData.jobBodyOK)),
    } as unknown as IJob);
    testJob.body.schedules = [
      {
        enabled: true,
        startDateTime: "2018-01-31T20:54:23.071Z",
        eachNWeek: "1",
        dayOfWeek: ["mon", "wed", "fri"],
        dailyFrequency: { occursOnceAt: "11:11:11" },
      },
    ];
    const tJob: Job = new Job(testJob);
    const result = tJob.calculateNextRun();
    assert.include(result.errorList, labels.schedule.scheduleNoName);
  });

  it("1.5.3 calculateNextRun. schema is incorrect", async () => {
    const testJob = new Job({
      body: JSON.parse(JSON.stringify(testData.jobBodyOK)),
    } as unknown as IJob);
    testJob.body.schedules = [
      {
        name: "weird",
        enabled: true,
        iAmNotASchedule: 1,
      },
    ];
    const tJob: Job = new Job(testJob);
    const result = tJob.calculateNextRun();
    assert.include(result.errorList, "schema is incorrect");
  });

  it("1.5.4 calculateNextRun. Next run can not be calculated - no active schedules", async () => {
    const testJob = new Job({
      body: JSON.parse(JSON.stringify(testData.jobBodyOK)),
    } as unknown as IJob);
    testJob.body.schedules = [
      {
        enabled: false,
      },
    ];
    const tJob: Job = new Job(testJob);
    const result = tJob.calculateNextRun();
    assert.include(result.errorList, labels.schedule.nextRunCanNotBeCalculated);
  });

  it("1.6.1 updateNextRun. Type mismatch `nextRun`", async () => {
    const testJob = JSON.parse(JSON.stringify(testData.jobBodyOK));
    const tJob: Job = new Job({ body: testJob });
    return assert.isRejected(
      tJob.updateNextRun("a"),
      `Unable to calculate next run as Job object is not composed properly`
    );
  });

  it("1.6.2 updateNextRun. Type mismatch `nextRun`", async () => {
    const testJob = JSON.parse(JSON.stringify(testData.jobBodyOK));
    const tJob: Job = new Job({ body: testJob });
    return assert.isRejected(
      tJob.updateNextRun(null),
      `Unable to calculate next run as Job object is not composed properly`
    );
  });

  it("1.6.2 updateNextRun. Job not composed properly", async () => {
    try {
      const dJob = new Job();
      dJob.updateNextRun("12.12.12");
    } catch (e) {
      assert.include(
        (e as unknown as Record<string, unknown>).stack,
        "not composed properly"
      );
    }
  });

  it("1.7.1 updateLastRun. Job not composed properly", async () => {
    try {
      const dJob = new Job();
      dJob.updateLastRun(true);
    } catch (e) {
      assert.include(
        (e as unknown as Record<string, unknown>).stack,
        "not composed properly"
      );
    }
  });

  it("1.8.1 updateStatus. No id", async () => {
    try {
      const dJob = new Job();
      dJob.updateStatus(1);
    } catch (e) {
      assert.include(
        (e as unknown as Record<string, unknown>).stack,
        "doesn't have an ID"
      );
    }
  });

  it("1.8.2 updateStatus. Incorrect status", async () => {
    const testJob = JSON.parse(JSON.stringify(testData.jobBodyOK));
    const tJob: Job = new Job({ body: testJob });
    tJob.id = 1;
    return assert.isRejected(tJob.updateStatus(3), "Status should be 1 or 2");
  });

  it("1.9.1 logHistory. No id", async () => {
    try {
      const dJob = new Job();
      dJob.logHistory({ "a": 1 }, config.testUser);
    } catch (e) {
      assert.include(
        (e as unknown as Record<string, unknown>).stack,
        "doesn't have an ID"
      );
    }
  });

  it("1.10.1 execute. Job not composed properly", async () => {
    const dJob = new Job();
    const result = await dJob.execute(config.testUser);
    assert.isFalse(result.success);
    assert.include((result.error as Error).message, "is not composed properly");
  });

  it("1.10.2 execute. Step 1 success, quitWithSuccess", async () => {
    const eJob = new Job({
      body: JSON.parse(JSON.stringify(testData.jobBodyOK)),
    } as unknown as IJob);
    await eJob.save(config.testUser);

    const stub = sinon
      .stub(eJob.body.steps[0], "execute")
      .resolves({ result: true, affected: 1 });
    try {
      eJob.body.steps[0].onSucceed = SimpleStepActionType.quitWithSuccess;
      await eJob.execute(config.testUser);
      const jobRecord = (await Job.get(eJob.id as number)) as Job;
      assert.isTrue(jobRecord.lastRunResult);
    } finally {
      stub.restore();
    }
  });

  it("1.10.2.1 execute. Step 1 success, quitWithFailure", async () => {
    const eJob = new Job({
      body: JSON.parse(JSON.stringify(testData.jobBodyOK)),
    } as unknown as IJob);
    await eJob.save(config.testUser);
    const stub = sinon
      .stub(eJob.body.steps[0], "execute")
      .resolves({ result: true, affected: 1 });
    try {
      eJob.body.steps[0].onSucceed = SimpleStepActionType.quitWithFailure;
      await eJob.execute(config.testUser);
      const jobRecord = (await Job.get(eJob.id as number)) as Job;
      assert.isFalse(jobRecord.lastRunResult);
    } finally {
      stub.restore();
    }
  });
  it("1.10.3 execute. Step 1 success, gotoNextStep, failed to repeat step 2, quitWithFailure finally", async () => {
    const eJob = new Job({
      body: JSON.parse(JSON.stringify(testData.jobBodyOK)),
    } as unknown as IJob);
    await eJob.save(config.testUser);
    const stub0 = sinon
      .stub(eJob.body.steps[0], "execute")
      .resolves({ result: true, affected: 1 });
    const stub1 = sinon
      .stub(eJob.body.steps[1], "execute")
      .resolves({ result: false, error: "execute_error" });
    const stub2 = sinon
      .stub(eJob.body.steps[1], "delayedExecute")
      .resolves({ result: false, error: "attemp_error" });
    try {
      await eJob.execute(config.testUser);
      const jobRecord = (await Job.get(eJob.id as number)) as Job;
      assert.isFalse(jobRecord.lastRunResult);
    } finally {
      stub0.restore();
      stub1.restore();
      stub2.restore();
    }
  });

  it("1.10.4 execute. Step 1 success, gotoNextStep, failed to repeat step 2, quitWithSuccess finally", async () => {
    const eJob = new Job({
      body: JSON.parse(JSON.stringify(testData.jobBodyOK)),
    } as unknown as IJob);
    await eJob.save(config.testUser);
    const stub0 = sinon
      .stub(eJob.body.steps[0], "execute")
      .resolves({ result: true, affected: 1 });
    eJob.body.steps[0].onSucceed = SimpleStepActionType.gotoNextStep;
    const stub1 = sinon
      .stub(eJob.body.steps[1], "execute")
      .resolves({ result: false, error: "execute_error" });
    const stub2 = sinon
      .stub(eJob.body.steps[1], "delayedExecute")
      .resolves({ result: false, error: "attemp_error" });
    try {
      eJob.body.steps[1].onFailure = SimpleStepActionType.quitWithSuccess;
      await eJob.execute(config.testUser);
      const jobRecord = (await Job.get(eJob.id as number)) as Job;
      assert.isTrue(jobRecord.lastRunResult);
    } finally {
      stub0.restore();
      stub1.restore();
      stub2.restore();
    }
  });

  it("1.10.5 execute. Step 1 success, gotoNextStep, failed to repeat step 2, quitWithSuccess finally", async () => {
    const eJob = new Job({
      body: JSON.parse(JSON.stringify(testData.jobBodyOK)),
    } as unknown as IJob);
    await eJob.save(config.testUser);
    const stub0 = sinon
      .stub(eJob.body.steps[0], "execute")
      .resolves({ result: true, affected: 1 });
    const stub1 = sinon
      .stub(eJob.body.steps[1], "execute")
      .resolves({ result: false, error: "execute_error" });
    const stub2 = sinon
      .stub(eJob.body.steps[1], "delayedExecute")
      .resolves({ result: false, error: "attemp_error" });
    try {
      eJob.body.steps[1].onFailure = SimpleStepActionType.gotoNextStep;
      await eJob.execute(config.testUser);
      const jobRecord = (await Job.get(eJob.id as number)) as Job;
      assert.isTrue(jobRecord.lastRunResult);
    } finally {
      stub0.restore();
      stub1.restore();
      stub2.restore();
    }
  });

  it("1.10.6 execute. Step 1 success, gotoNextStep, success on repeating, gotoNextStep finally", async () => {
    const eJob = new Job({
      body: JSON.parse(JSON.stringify(testData.jobBodyOK)),
    } as unknown as IJob);
    await eJob.save(config.testUser);
    const stub0 = sinon
      .stub(eJob.body.steps[0], "execute")
      .resolves({ result: true, affected: 1 });
    const stub1 = sinon
      .stub(eJob.body.steps[1], "execute")
      .resolves({ result: false, error: "execute_error" });
    const stub2 = sinon
      .stub(eJob.body.steps[1], "delayedExecute")
      .resolves({ result: true, error: "attemp_error" });
    try {
      eJob.body.steps[1].onSucceed = SimpleStepActionType.gotoNextStep;
      await eJob.execute(config.testUser);
      const jobRecord = (await Job.get(eJob.id as number)) as Job;
      assert.isTrue(jobRecord.lastRunResult);
    } finally {
      stub0.restore();
      stub1.restore();
      stub2.restore();
    }
  });

  it("1.10.7 execute. Step 1 success, gotoNextStep, success on repeating, quitWithSuccess finally", async () => {
    const eJob = new Job({
      body: JSON.parse(JSON.stringify(testData.jobBodyOK)),
    } as unknown as IJob);
    await eJob.save(config.testUser);
    const stub0 = sinon
      .stub(eJob.body.steps[0], "execute")
      .resolves({ result: true, affected: 1 });
    const stub1 = sinon
      .stub(eJob.body.steps[1], "execute")
      .resolves({ result: false, error: "execute_error" });
    const stub2 = sinon
      .stub(eJob.body.steps[1], "delayedExecute")
      .resolves({ result: true, affected: 1 });
    try {
      eJob.body.steps[1].onSucceed = SimpleStepActionType.quitWithSuccess;
      await eJob.execute(config.testUser);
      const jobRecord = (await Job.get(eJob.id as number)) as Job;
      assert.isTrue(jobRecord.lastRunResult);
    } finally {
      stub0.restore();
      stub1.restore();
      stub2.restore();
    }
  });

  it("1.10.8 execute. Step 1 success, gotoNextStep, success on repeating, quitWithFailure finally", async () => {
    const eJob = new Job({
      body: JSON.parse(JSON.stringify(testData.jobBodyOK)),
    } as unknown as IJob);
    await eJob.save(config.testUser);
    const stub0 = sinon
      .stub(eJob.body.steps[0], "execute")
      .resolves({ result: true, affected: 1 });
    const stub1 = sinon
      .stub(eJob.body.steps[1], "execute")
      .resolves({ result: false, error: "execute_error" });
    const stub2 = sinon
      .stub(eJob.body.steps[1], "delayedExecute")
      .resolves({ result: true, error: "attemp_error" });
    try {
      eJob.body.steps[1].onSucceed = SimpleStepActionType.quitWithFailure;
      await eJob.execute(config.testUser);
      const jobRecord = (await Job.get(eJob.id as number)) as Job;
      assert.isFalse(jobRecord.lastRunResult);
    } finally {
      stub0.restore();
      stub1.restore();
      stub2.restore();
    }
  });

  it("1.10.9 execute. Step list is empty", async () => {
    const spy = sinon.spy(log, "error");
    try {
      const newJob = new Job({
        body: JSON.parse(JSON.stringify(testData.jobBodyOK)),
      });
      newJob.body.steps = [];
      await newJob.execute(config.testUser);
      assert.include(spy.args[0][0], "object is not composed properly");
    } finally {
      spy.restore();
    }
  });
  it("1.11.1 1-minute execution test. Create connection, create 21 jobs, wait 1 minutes, check if records were created in DB", async function () {
    //config.skipLongTests = false;
    if (config.skipLongTests) {
      this.skip();
    } else {
      const numberOfJobs = 20;
      const minutes = 1;
      let connBody = process.env.APP_ENV === "qa" ? testData.execution.connectionQa : testData.execution.connectionLocal;
      const connection = new Connection(
         connBody as ConnectionBody
      );
      await connection.save(config.testUser);

      const uid = nanoid();

      for (let index = 0; index < numberOfJobs; index++) {
        const body = JSON.parse(JSON.stringify(testData.execution.job));
        body.name = `Execution test job ${index}`;
        body.steps[0].command = body.steps[0].command.replace(
          "insert_value",
          `Potatoe${index}-${uid}`
        );
        body.steps[0].connection = connection.id;
        const job = new Job({ body: body });
        await job.save(config.testUser);
      }
      //Run execution loop for {minutes} minutes
      //Main loop
      console.log(
        `🚀 Starting execution loop at ${Date()}, test sleep for ${minutes} minutes...`
      );
      const context = new Engine(config.runTolerance);
      const t = setInterval(function () {
        return context.run();
      }, config.runInterval);
      //Startup actions
      Engine.updateOverdueJobs();
      Engine.resetAllJobsStatuses();
      //Run loop for 5 minutes
      await new Promise((resolve) => setTimeout(resolve, 60000 * minutes));
      console.log(`🚀 Finishing execution loop at ${Date()}`);
      clearInterval(t);
      const rowCount = await new Promise((resolve, reject) => {
        const query = {
          "text": `SELECT count(id) FROM public."sysAbyss" where "text" like '%${uid}%'`,
        };
        executeSysQuery(query, (err, result) => {
          if (result.rows)
            resolve(
              (result.rows[0] as unknown as Record<string, unknown>)
                .count as number
            );
          else reject(0);
        });
      });

      assert.equal(rowCount, numberOfJobs * minutes);
    }
  }).timeout(305000);

  it("1.11.1 run. Error while trying execute run", async () => {
    const context = new Engine(0);
    const spy = sinon.spy(log, "error");
    try {
      assert.doesNotThrow(context.run);
      assert.include(spy.args[0][0], "Cannot read property");
    } finally {
      spy.restore();
    }
  });
});
