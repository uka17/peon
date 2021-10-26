/* eslint-disable no-unused-vars */
/* eslint-disable no-case-declarations */
/* eslint-disable no-prototype-builtins */
// engines/job.js
const validation = require("../tools/validation");
const schedulator = require("schedulator");
const util = require("../tools/util");
const dbclient = require("../tools/db");
const log = require("../../log/dispatcher");
const stepEngine = require("./step");
const labels = require("../../config/message_labels")("en");

/**
 * Returns Job count accordingly to filtering
 * @param {string} filter Filter will be applied to `name` and `description` columns
 * @returns {Promise} Promise which resolves with numeber of Job objects in case of success and rejects with error in case of failure
 */
function getJobCount(filter) {
  return new Promise((resolve, reject) => {
    const query = {
      "text": 'SELECT public."fnJob_Count"($1) as count',
      "values": [filter],
    };
    dbclient.query(query, (err, result) => {
      try {
        /* istanbul ignore if */
        if (err) {
          throw new Error(err);
        } else {
          resolve(result.rows[0].count);
        }
      } catch (e) /*istanbul ignore next*/ {
        log.error(`Failed to get job count with query ${query}. Stack: ${e}`);
        reject(e);
      }
    });
  });
}
module.exports.getJobCount = getJobCount;

/**
 * Returns Job list accordingly to filtering, sorting, page order and page number
 * @param {string} filter Filter will be applied to `name` and `description` columns
 * @param {string} sortColumn Name of sorting column
 * @param {string} sortOrder Sorting order (`asc` or `desc`)
 * @param {number} perPage Number of record per page
 * @param {number} page Page number
 * @returns {Promise} Promise which resolves with list of `Job` objects in case of success, `null` in case if Job list is empty and rejects with error in case of failure
 */
function getJobList(filter, sortColumn, sortOrder, perPage, page) {
  return new Promise((resolve, reject) => {
    try {
      if (sortOrder !== "asc" && sortOrder !== "desc")
        throw new TypeError("sortOrder should have value `asc` or `desc`");
      if (typeof parseInt(perPage) !== "number" || isNaN(parseInt(perPage)))
        throw new TypeError("perPage should be a number");
      if (typeof parseInt(page) !== "number" || isNaN(parseInt(page)))
        throw new TypeError("page should be a number");
      const query = {
        "text": 'SELECT public."fnJob_SelectAll"($1, $2, $3, $4, $5) as jobs',
        "values": [
          filter,
          sortColumn,
          sortOrder,
          parseInt(perPage),
          parseInt(page),
        ],
      };
      dbclient.query(query, (err, result) => {
        try {
          /*istanbul ignore if*/
          if (err) {
            throw new Error(err);
          } else {
            /* istanbul ignore if */
            if (result.rows[0].jobs == null) {
              resolve(null);
            } else resolve(result.rows[0].jobs);
          }
        } catch (e) /*istanbul ignore next*/ {
          log.error(`Failed to get job list with query ${query}. Stack: ${e}`);
          reject(e);
        }
      });
    } catch (err) {
      log.error(`Parameters type mismatch. Stack: ${err}`);
      reject(err);
    }
  });
}
module.exports.getJobList = getJobList;

/**
 * Returns Job by id
 * @param {number} jobId Id of Job
 * @returns {Promise} Promise which resolves with `Job` in case of success, `null` if Job is not found by `id` and rejects with error in case of failure
 */
function getJob(jobId) {
  return new Promise((resolve, reject) => {
    try {
      if (typeof parseInt(jobId) !== "number" || isNaN(parseInt(jobId)))
        throw new TypeError("jobId should be a number");
      const query = {
        "text": 'SELECT public."fnJob_Select"($1) as job',
        "values": [parseInt(jobId)],
      };
      dbclient.query(query, (err, result) => {
        try {
          /*istanbul ignore if*/
          if (err) {
            throw new Error(err);
          } else {
            /* istanbul ignore if */
            if (result.rows[0].job == null) {
              resolve(null);
            } else resolve(result.rows[0].job);
          }
        } catch (e) /*istanbul ignore next*/ {
          log.error(`Failed to get job with query ${query}. Stack: ${e}`);
          reject(e);
        }
      });
    } catch (err) {
      log.error(`Parameters type mismatch. Stack: ${err}`);
      reject(err);
    }
  });
}
module.exports.getJob = getJob;

/**
 * Creates new job
 * @param {Object} job Job object to be created
 * @param {string?} createdBy User who creates job
 * @returns {Promise} Promise which resolves with just created job with `id` in case of success and rejects with error in case of failure
 */
function createJob(job, createdBy) {
  return new Promise((resolve, reject) => {
    try {
      if (typeof job !== "object")
        throw new TypeError("job should be an object");
      if (typeof createdBy !== "string")
        throw new TypeError("createdBy should be a string");
      const query = {
        "text": 'SELECT public."fnJob_Insert"($1, $2) as id',
        "values": [job, createdBy],
      };
      dbclient.query(query, async (err, result) => {
        try {
          /*istanbul ignore if*/
          if (err) {
            throw new Error(err);
          } else {
            let newBornJob = await module.exports.getJob(result.rows[0].id);
            resolve(newBornJob);
          }
        } catch (e) /*istanbul ignore next*/ {
          log.error(`Failed to create job with content ${job}. Stack: ${e}`);
          reject(e);
        }
      });
    } catch (err) {
      log.error(`Parameters type mismatch. Stack: ${err}`);
      reject(err);
    }
  });
}
module.exports.createJob = createJob;

/**
 * Updates job by id
 * @param {number} jobId Id of job to be updated
 * @param {Object} job Content for Job update
 * @param {string} updatedBy User who updates job
 * @returns {Promise} Promise which resolves with number of updated rows in case of success and rejects with error in case of failure
 */
function updateJob(jobId, job, updatedBy) {
  return new Promise((resolve, reject) => {
    try {
      if (typeof parseInt(jobId) !== "number" || isNaN(parseInt(jobId)))
        throw new TypeError("jobId should be a number");
      if (typeof job !== "object")
        throw new TypeError("job should be an object");
      if (typeof updatedBy !== "string")
        throw new TypeError("updatedBy should be a string");
      const query = {
        "text": 'SELECT public."fnJob_Update"($1, $2, $3) as count',
        "values": [parseInt(jobId), job, updatedBy],
      };
      dbclient.query(query, async (err, result) => {
        try {
          /*istanbul ignore if*/
          if (err) {
            throw new Error(err);
          } else {
            resolve(result.rows[0].count);
          }
        } catch (e) /*istanbul ignore next*/ {
          log.error(`Failed to update job with query ${query}. Stack: ${e}`);
          reject(e);
        }
      });
    } catch (err) {
      log.error(`Parameters type mismatch. Stack: ${err}`);
      reject(err);
    }
  });
}
module.exports.updateJob = updateJob;

/**
 * Marks job in DB as deleted by id
 * @param {number} jobId Id of job to be deleted
 * @param {string} deletedBy User updateJobNextRunho deletes job
 * @returns {Promise} Promise which resolves with number of deleted rows in case of success and rejects with error in case of failure
 */
function deleteJob(jobId, deletedBy) {
  return new Promise((resolve, reject) => {
    try {
      if (typeof parseInt(jobId) !== "number" || isNaN(parseInt(jobId)))
        throw new TypeError("jobId should be a number");
      if (typeof deletedBy !== "string")
        throw new TypeError("deletedBy should be a string");
      const query = {
        "text": 'SELECT public."fnJob_Delete"($1, $2) as count',
        "values": [parseInt(jobId), deletedBy],
      };
      dbclient.query(query, async (err, result) => {
        try {
          /*istanbul ignore next*/
          if (err) {
            throw new Error(err);
          } else {
            resolve(result.rows[0].count);
          }
        } catch (e) /*istanbul ignore next*/ {
          log.error(`Failed to delete job with query ${query}. Stack: ${e}`);
          reject(e);
        }
      });
    } catch (err) {
      log.error(`Parameters type mismatch. Stack: ${err}`);
      reject(err);
    }
  });
}
module.exports.deleteJob = deleteJob;

/**
 * @typedef {Object} NextRunResult
 * @property {boolean} isValid Assesment result
 * @property {string=} errorList If `isValid` is `false` represents error list as `string`
 * @property {string=} nextRun If `isValid` is `true` represents next run `date-time`
 */
/**
 * Validates job and calculates next run date and time for it
 * @param {Object} job Job which should be used for calculation
 * @return {NextRunResult} Next run result
 */
function calculateNextRun(job) {
  try {
    if (typeof job !== "object") throw new TypeError("job should be an object");

    let validationSequence = ["job", "steps", "notifications", "schedules"];
    let jobValidationResult;
    for (let i = 0; i < validationSequence.length; i++) {
      switch (validationSequence[i]) {
        case "job":
          jobValidationResult = validation.validateJob(job);
          break;
        case "steps":
          jobValidationResult = validation.validateStepList(job.steps);
          break;
        case "notifications":
          //TODO validation for notification
          //jobValidationResult = validation.validateStepList(job.steps)
          break;
        case "schedules":
          let nextRunList = [];
          if (job.schedules) {
            for (let i = 0; i < job.schedules.length; i++) {
              if (job.schedules[i].enabled) {
                if (!job.schedules[i].hasOwnProperty("name"))
                  throw new Error(labels.schedule.scheduleNoName);
                let nextRun = schedulator.nextOccurrence(job.schedules[i]);
                if (nextRun.result != null) nextRunList.push(nextRun.result);
                else if (nextRun.error.includes("schema is incorrect"))
                  throw new Error(`schedule[${i}] ${nextRun.error}`);
              }
            }
          }
          if (nextRunList.length == 0)
            throw new Error(labels.schedule.nextRunCanNotBeCalculated);
          else
            jobValidationResult = {
              "isValid": true,
              "nextRun": util.getMinDateTime(nextRunList),
            };
          break;
      }
      if (!jobValidationResult.isValid) return jobValidationResult;
    }
    return jobValidationResult;
  } catch (e) {
    log.warn(
      `Failed to calculate next run for job (jobId=${job.id}). Stack: ${e}`
    );
    return { "isValid": false, "errorList": e.message };
  }
}
module.exports.calculateNextRun = calculateNextRun;
/**
 * Calculates and save Job next run
 * @param {number} jobId Job id
 * @param {string} nextRun `date-time` of job next run
 * @returns {Promise} Promise which returns `true` in case of success and `false` in case of failure
 */
function updateJobNextRun(jobId, nextRun) {
  return new Promise((resolve, reject) => {
    try {
      if (typeof parseInt(jobId) !== "number" || isNaN(parseInt(jobId)))
        throw new TypeError("jobId should be a number");
      if (!(util.parseDateTime(nextRun) instanceof Date))
        throw new TypeError("nextRun should be a date");
      const query = {
        "text": 'SELECT public."fnJob_UpdateNextRun"($1, $2) as count',
        "values": [parseInt(jobId), nextRun],
      };
      dbclient.query(query, (err, result) => {
        try {
          /*istanbul ignore if*/
          if (err) {
            throw new Error(err);
          } else {
            resolve(true);
          }
        } catch (e) /*istanbul ignore next*/ {
          log.error(
            `Failed to update job next run with query ${query}. Stack: ${e}`
          );
          reject(e);
        }
      });
    } catch (err) {
      log.error(`Parameters type mismatch. Stack: ${err}`);
      reject(err);
    }
  });
}
module.exports.updateJobNextRun = updateJobNextRun;

/**
 * Changes Job last run result. Last run date-time will be updated with current timestamp.
 * @param {number} jobId Job id
 * @param {number} runResult Job run result. `true` - success, `false` - failure
 * @returns {Promise} Promise which returns `true` in case of success and `false` in case of failure
 */
function updateJobLastRun(jobId, runResult) {
  return new Promise((resolve, reject) => {
    try {
      if (typeof jobId !== "number" || isNaN(parseInt(jobId)))
        throw new TypeError("jobId should be a number");
      if (typeof runResult !== "boolean")
        throw new TypeError("runResult should be boolean");
      const query = {
        "text": 'SELECT public."fnJob_UpdateLastRun"($1, $2) as updated',
        "values": [jobId, runResult],
      };

      // eslint-disable-next-line no-unused-vars
      dbclient.query(query, (err, result) => {
        try {
          /*istanbul ignore if*/
          if (err) {
            throw new Error(err);
          } else resolve(true);
        } catch (e) /*istanbul ignore next*/ {
          log.error(
            `Failed to update job last run with query ${query}. Stack: ${e}`
          );
          reject(e);
        }
      });
    } catch (err) {
      log.error(`Parameters type mismatch. Stack: ${err}`);
      reject(err);
    }
  });
}
module.exports.updateJobLastRun = updateJobLastRun;

/**
 * Changes Job status
 * @param {number} jobId Job id
 * @param {number} status Status id. `1` - idle, `2` - execution
 * @returns {Promise} Promise which returns `true` in case of success and `false` in case of failure
 */
function updateJobStatus(jobId, status) {
  return new Promise((resolve, reject) => {
    try {
      if (typeof jobId !== "number" || isNaN(parseInt(jobId)))
        throw new TypeError("jobId should be a number");
      if (status !== 1 && status !== 2)
        throw new TypeError("status should be 1 or 2");
      const query = {
        "text": 'SELECT public."fnJob_UpdateStatus"($1, $2) as updated',
        "values": [jobId, status],
      };

      // eslint-disable-next-line no-unused-vars
      dbclient.query(query, (err, result) => {
        try {
          /*istanbul ignore if*/
          if (err) {
            throw new Error(err);
          } else resolve(true);
        } catch (e) /*istanbul ignore next*/ {
          log.error(
            `Failed to update job status with query ${query}. Stack: ${e}`
          );
          reject(e);
        }
      });
    } catch (err) {
      log.error(`Parameters type mismatch. Stack: ${err}`);
      reject(err);
    }
  });
}
module.exports.updateJobStatus = updateJobStatus;

/**
 * Creates new entry for job history
 * @param {string} message `json` message to log
 * @param {number} jobId Id of job
 * @param {string} createdBy Author of message
 * @param {?string} uid Session id. Default is `null`
 * @returns {Promise} Promise which returns `true` in case of success and error in case of failure
 */
function logJobHistory(message, jobId, createdBy, uid) {
  return new Promise((resolve, reject) => {
    try {
      if (typeof jobId !== "number" || isNaN(parseInt(jobId)))
        throw new TypeError("jobId should be a number");
      if (typeof createdBy !== "string")
        throw new TypeError("createdBy should be a string");
      const query = {
        "text":
          'SELECT public."fnJobHistory_Insert"($1, $2, $3, $4) as updated',
        "values": [message, uid, jobId, createdBy],
      };

      log.info(
        `Job (id=${jobId}). ${message.message}${
          message.error ? ": " + message.error : ""
        }`
      );

      // eslint-disable-next-line no-unused-vars
      dbclient.query(query, (err, result) => {
        try {
          /*istanbul ignore if*/
          if (err) {
            throw new Error(err);
          } else resolve(true);
        } catch (e) /*istanbul ignore next*/ {
          log.error(
            `Failed to add record to log job history with query ${query}. Stack: ${e}`
          );
          reject(e);
        }
      });
    } catch (err) {
      log.error(`Parameters type mismatch. Stack: ${err}`);
      reject(err);
    }
  });
}
module.exports.logJobHistory = logJobHistory;

/**
 * Executes Job (including logging steps results, changing Job last run result and `date-time`, calculates next run `date-time`).
 * @param {Object} jobRecord Job record for execution
 * @param {string} executedBy User who is executing job
 * @param {?string} uid Session id. Default is `null`
 */
async function executeJob(jobRecord, executedBy, uid) {
  try {
    if (jobRecord === null || jobRecord === undefined)
      throw new Error(
        `Failed to get job (jobRecord=${jobRecord}) for execution`
      );
    if (typeof executedBy !== "string")
      throw new TypeError("executedBy should be a string");
    await logJobHistory(
      { message: labels.execution.jobStarted, level: 2 },
      jobRecord.id,
      executedBy,
      uid
    );
    let job = jobRecord.job;
    let jobExecutionResult = true;
    if (job.hasOwnProperty("steps") && job.steps.length > 0) {
      //TODO sort steps in right order
      step_loop: for (
        let stepIndex = 0;
        stepIndex < job.steps.length;
        stepIndex++
      ) {
        const step = job.steps[stepIndex];
        await logJobHistory(
          { message: labels.execution.executingStep(step.name), level: 2 },
          jobRecord.id,
          executedBy,
          uid
        );
        let stepExecution = await stepEngine.execute(step);
        //log execution result
        if (stepExecution.result) {
          await logJobHistory(
            {
              message: labels.execution.stepExecuted(step.name),
              rowsAffected: stepExecution.affected,
              level: 2,
            },
            jobRecord.id,
            executedBy,
            uid
          );
          //take an action based on execution result
          switch (step.onSucceed) {
            case "gotoNextStep":
              break;
            case "quitWithSuccess":
              jobExecutionResult = true;
              break step_loop;
            case "quitWithFailure":
              jobExecutionResult = false;
              break step_loop;
          }
        } else {
          await logJobHistory(
            {
              message: labels.execution.stepFailed(step.name),
              error: stepExecution.error,
              level: 0,
            },
            jobRecord.id,
            executedBy,
            uid
          );
          let repeatSucceeded = false;
          //There is a requierement to try to repeat step in case of failure
          if (step.retryAttempts.number > 0) {
            attempt_loop: for (
              let attempt = 0;
              attempt < step.retryAttempts.number;
              attempt++
            ) {
              await logJobHistory(
                {
                  message: labels.execution.repeatingStep(
                    step.name,
                    attempt + 1,
                    step.retryAttempts.number
                  ),
                  level: 2,
                },
                jobRecord.id,
                executedBy,
                uid
              );
              let repeatExecution = await stepEngine.delayedExecute(
                step,
                step.retryAttempts.interval
              );
              if (repeatExecution.result) {
                await logJobHistory(
                  {
                    message: labels.execution.stepRepeatSuccess(
                      step.name,
                      attempt + 1
                    ),
                    rowsAffected: stepExecution.affected,
                    level: 2,
                  },
                  jobRecord.id,
                  executedBy,
                  uid
                );
                //take an action based on execution result
                switch (step.onSucceed) {
                  case "gotoNextStep":
                    repeatSucceeded = true;
                    break attempt_loop;
                  case "quitWithSuccess":
                    jobExecutionResult = true;
                    break step_loop;
                  case "quitWithFailure":
                    jobExecutionResult = false;
                    break step_loop;
                }
              } else {
                await logJobHistory(
                  {
                    message: labels.execution.stepRepeatFailure(
                      step.name,
                      attempt + 1
                    ),
                    error: stepExecution.error,
                    level: 0,
                  },
                  jobRecord.id,
                  executedBy,
                  uid
                );
              }
            }
          }
          if (!repeatSucceeded) {
            //all aditional attempts failed
            switch (step.onFailure) {
              case "gotoNextStep":
                break;
              case "quitWithSuccess":
                jobExecutionResult = true;
                break step_loop;
              case "quitWithFailure":
                jobExecutionResult = false;
                break step_loop;
            }
          }
        }
      }
    } else {
      await logJobHistory(
        { message: labels.execution.jobNoSteps, level: 0 },
        jobRecord.id,
        executedBy,
        uid
      );
    }
    await updateJobLastRun(jobRecord.id, jobExecutionResult);
    if (jobExecutionResult) {
      await logJobHistory(
        { message: labels.execution.jobSuccessful, level: 2 },
        jobRecord.id,
        executedBy,
        uid
      );
    } else {
      await logJobHistory(
        { message: labels.execution.jobFailed, level: 0 },
        jobRecord.id,
        executedBy,
        uid
      );
    }

    let jobAssesmentResult = calculateNextRun(job);
    if (!jobAssesmentResult.isValid) {
      await updateJobNextRun(jobRecord.id, null);
    } else {
      await updateJobNextRun(
        jobRecord.id,
        jobAssesmentResult.nextRun.toUTCString()
      );
    }
  } catch (e) {
    log.error(
      `Error during execution of job (jobRecord=${jobRecord}). Stack: ${e}`
    );
  } finally {
    if (jobRecord !== null && jobRecord !== undefined)
      //module.exports is added for sake of unit testing
      await module.exports.updateJobStatus(jobRecord.id, 1);
  }
}
module.exports.executeJob = executeJob;

/**
 * Sorting Step list in a correct order and eliminates gaps in sorting order (e.g. 1,7,2,2,9 will be changed to 1,2,3,4,5)
 * @param {Array} stepList Array of step objects
 */
function normalizeStepList(stepList) {
  //sort steps in correct order
  if (!Array.isArray(stepList))
    throw new Error("stepList should have type Array");
  stepList.sort((a, b) => {
    if (!a.hasOwnProperty("order") || !b.hasOwnProperty("order"))
      throw new Error(
        `All 'step' objects in the list should have 'order' property`
      );

    if (a.order < b.order) return -1;
    if (a.order > b.order) return 1;
    return 0;
  });
  //normilize
  for (let index = 0; index < stepList.length; index++) {
    stepList[index].order = index + 1;
  }
}

module.exports.normalizeStepList = normalizeStepList;

/*
async function test() {
  await executeJob(await getJob(768), config.testUser);
}
test();
*/
