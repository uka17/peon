// engines/job.js
const validation = require("../tools/validation");
const schedulator = require("schedulator");
const util = require('../tools/util')
const dbclient = require("../tools/db");
const log = require('../../log/dispatcher');
const stepEngine = require('./step');
const labels = require('../../config/message_labels')('en');

/**
 * Returns job by id
 * @param {number} jobId Id of job
 * @returns {Promise} Promise which returns job in case of success and `null` in case of failure 
 */
function getJob(jobId) {
  return new Promise((resolve, reject) => {
    const query = {
      "text": 'SELECT public."fnJob_Select"($1) as job',
      "values": [jobId]
    };
    dbclient.query(query, (err, result) => {  
      /* istanbul ignore if */
      if (err) {
        log.error(`Failed to get job by id=${jobId}. Stack: ${err.stack}`);
      } else {
        if(result.rows[0].job == null) {
          log.warn(`No any job found by id=${jobId}`);
          reject(null);
        }
        else
          resolve(result.rows[0].job);
      } 
    });
  });
}
/**
 * Creates new job in DB
 * @param {Object} job Job object to be created in DB
 * @param {string?} createdBy User who creates job
 * @returns {Object} Just created job with `id` in case of success, standart user error message with `logId` otherwise
 */
function createJob(job, createdBy) {
  return new Promise(async (resolve, reject) => {
    const query = {
      "text": 'SELECT public."fnJob_Insert"($1, $2, $3) as id',
      "values": [job, job.nextRun.toUTCString(), createdBy]
    };
    dbclient.query(query, async (err, result) => {           
      try {
        if (err) { 
          reject(err);
        } else {
          job.id = result.rows[0].id;
          resolve(job);
        }
      }
      catch(e) {
        reject(e);
      }
    });
  });
}
module.exports.createJob = createJob;

/**
 * Update job in DB by id
 * @param {number} id Id of job to be updated
 * @param {Object} job Job object to be updated in DB
 * @param {string} updatedBy User who creates job
 * @returns {number | Object} Number of updated rows, standart user error message with `logId` otherwise
 */
function updateJob(id, job, updatedBy) {
  return new Promise(async (resolve, reject) => {
    const query = {
      "text": 'SELECT public."fnJob_Update"($1, $2, $3, $4) as count',
      "values": [id, job, job.nextRun.toUTCString(), updatedBy]
    };
    dbclient.query(query, async (err, result) => {           
      try {
        if (err) { 
          reject(err);
        } else {    
          resolve(result.rows[0].count);
        }
      }
      catch(e) {
        reject(e);
      }
    });
  });
}
module.exports.updateJob = updateJob;

/**
 * Mark job in DB as deleted by id
 * @param {number} id Id of job to be updated
 * @param {string} deletedBy User who deletes job
 * @returns {number | Object} Number of updated rows, standart user error message with `logId` otherwise
 */
function deleteJob(id, deletedBy) {
  return new Promise(async (resolve, reject) => {
    const query = {
      "text": 'SELECT public."fnJob_Delete"($1) as count',
      "values": [id]
    };
    dbclient.query(query, async (err, result) => {           
      try {
        if (err) { 
          reject(err);
        } else {    
          resolve(result.rows[0].count);
        }
      }
      catch(e) {
        reject(e);
      }
    });
  });
}
module.exports.deleteJob = deleteJob;

/**
 * @typedef {Object} NextRunResult
 * @property {boolean} isValid Assesment result
 * @property {string=} errorList If `isValid` is `false` represents error list as `string`
 * @property {string=} nextRun If `isValid` is `true` represents next run date-time
 */
/**
 * Validates job and calculates next run date and time for it
 * @param {Object} job Job which should be used for calculation
 * @return {NextRunResult} Next run result
 */
function calculateNextRun(job) {
  try {
    let validationSequence = ["job", "steps", "notifications", "schedules"];
    let jobValidationResult;
    for (i = 0; i < validationSequence.length; i++) {
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
              if (
                job.schedules[i].enabled ||
                !job.schedules[i].hasOwnProperty("enabled")
              ) {
                let nextRun = schedulator.nextOccurrence(job.schedules[i]);
                if (nextRun.result != null) nextRunList.push(nextRun.result);
                else if (nextRun.error.includes("schema is incorrect"))
                  return {
                    "isValid": false,
                    "errorList": `schedule[${i}] ${nextRun.error}`
                  };
              }
            }
          }
          if (nextRunList.length == 0)
            return {
              "isValid": false,
              "errorList": messageBox.schedule.nextRunCanNotBeCalculated
            };
          else
            jobValidationResult = {
              "isValid": true,
              "nextRun": util.getMinDateTime(nextRunList)
            };
          break;
      }
      if (!jobValidationResult.isValid) 
        return jobValidationResult;
    }
    return jobValidationResult;
  }
  catch(e) {
    log.error(`Failed to calculate next run for job (id=${job.id}). Stack: ${err.stack}`);
    return {"isValid": false, "errorList": e.message};
  }
}
module.exports.calculateNextRun = calculateNextRun;
/**
 * Calculates and save job next run
 * @param {number} jobId Job id
 * @param {string} executedBy Author of change
 * @returns {Promise} Promise which returns `true` in case of success and `false` in case of failure 
 */
function updateJobNextRun(jobId, executedBy) {
  return new Promise(async (resolve, reject) => {
    let record = await getJob(jobId);
    let JobAssesmentResult = calculateNextRun(record.job);
    const query = {
      "text": 'SELECT public."fnJob_UpdateNextRun"($1, $2, $3) as count',
      "values": [jobId, JobAssesmentResult.nextRun.toUTCString(), executedBy]
    };
    dbclient.query(query, (err, result) => {     
      if (err) {
        log.error(`Failed to update job (id=${jobId}) next run date-time with ${JobAssesmentResult.nextRun}. Stack: ${err.stack}`)
        reject(false);
      } else {
        resolve(true);
      } 
    });
  });
}

/**
 * Changes job status
 * @param {number} jobId Job id
 * @param {number} status Status id. `1` - idle, `2` - execution
 * @param {string} executedBy Author of change 
 * @returns {Promise} Promise which returns `true` in case of success and `false` in case of failure
 */
function updateJobStatus(jobId, status, executedBy) {
  return new Promise((resolve, reject) => {
    const query = {
      "text": 'SELECT public."fnJob_UpdateStatus"($1, $2, $3) as updated',
      "values": [jobId, status, executedBy]
    };                  

    dbclient.query(query, (err, result) => {
        if (err) {
          log.error(`Failed to change job (id=${jobId}) status to '${status}'. Stack: ${err.stack}`);
          reject(false);
        }
        else
          resolve(true);
    }); 
  });
}
module.exports.updateJobStatus = updateJobStatus;

/**
 * Creates new entry for job history
 * @param {string} message `json` message to log
 * @param {number} jobId Id of job
 * @param {string} createdBy Author of message
 * @param {?string} uid Session id. Default is `null` 
 * @returns {Promise} Promise which returns `true` in case of success and `false` in case of failure
 */
function logJobHistory(message, jobId, createdBy, uid) {
  return new Promise((resolve, reject) => {
    const query = {
      "text": 'SELECT public."fnJobHistory_Insert"($1, $2, $3, $4) as updated',
      "values": [message, uid, jobId, createdBy]
    };                  

    dbclient.query(query, (err, result) => {
        if (err) {
          log.error(`Failed to insert job history (id=${jobId}). Stack: ${err.stack}`);
          reject(false); 
        }
        else
          resolve(true); 
    }); 
  });
}

/**
 * Executes job
 * @param {number} jobId id of job for execution
 * @param {string} executedBy User who is executing job
 * @param {?string} uid Session id. Default is `null`  
 */
async function executeJob(jobId, executedBy, uid) {
  try {
    await logJobHistory({ message: labels.execution.jobStarted, level: 2 }, jobId, executedBy, uid);

    let job = (await getJob(jobId)).job;
    if(job !== null) {
      if(job.hasOwnProperty("steps") && job.steps.length > 0) {
        for (let i = 0; i < job.steps.length; i++) {
          const step = job.steps[i];
          await logJobHistory({ message: labels.execution.executingStep(step.name), level: 2 }, jobId, executedBy, uid);
          let stepExecution = await stepEngine.execute(step);
          if(stepExecution.result) {
            await logJobHistory(
              { 
                message: labels.execution.stepExecuted(step.name),
                rowsAffected: stepExecution.affected, 
                level: 2 
              }, 
              jobId, executedBy, uid);
          } else {
            await logJobHistory(
              { 
                message: labels.execution.stepFailed(step.name),
                error: stepExecution.error, 
                level: 0 
              }, 
              jobId, executedBy, uid);
          }
        }
      } else
        log.error(`Failed to get job step list (id=${jobId})`);
    } else
      log.error(`Failed to get job (id=${jobId}) for execution`);   

    await logJobHistory({ message: labels.execution.jobFinished, level: 2 }, jobId, executedBy, uid);
    log.info(`Job (id=${jobId}) successfully finsihed. usid: ${uid}`);
  }
  catch(e) {
    log.error(`Error during execution of job (id=${jobId}). Stack: ${e.stack}`);
  }
  finally {
    await updateJobNextRun(jobId, executedBy);
    await updateJobStatus(jobId, 1, executedBy);
  }  
}

module.exports.executeJob = executeJob;

