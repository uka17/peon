// engine/job.js
var validation = require("../tools/validation");
var schedulator = require("schedulator");
var util = require('../tools/util')
const dbclient = require("../tools/db");
const messageBox = require('../../config/message_labels');
const log = require('../../log/dispatcher');
var toJSON = require( 'utils-error-to-json' );

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
        log.error(`Failed to get job by id=${jobId}: ${err}`);
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
 * @typedef {Object} NextRunResult
 * @property {boolean} isValid Assesment result
 * @property {string=} errorList If `isValid` is `false` represents error list
 * @property {string=} nextRun If `isValid` is `true` represents next run date-time
 */
/**
 * Validates job and calculates next run date and time for it
 * @param {Object} job Job which should be used for calculation
 * @return {NextRunResult} Next run result
 */
function calculateNextRun(job) {
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
        log.error(`Can not update job next run date-time (id=${jobId} with ${JobAssesmentResult.nextRun}: ${toJSON(err)}`)
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
          log.error(`Error while changing job (id=${jobId}) status to '${status}': ${err.message}`);
          reject(false);
        }
        else
          resolve(true);
    }); 
  });
}

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
          log.error(`Error while trying to insert job history (id=${jobId}): ${toJSON(err)}`);
          reject(false); 
        }
        else
          resolve(true); 
    }); 
  });
}

/**
 * Executes job
 * @param {number} jobIdasync d of job for execution
 * @param {string} execuasync dBy User who is executing job
 * @param {?string} uid async ssion id. Default is `null`  
 */
async function executeJob(jobId, executedBy, uid) {
  try {
    await logJobHistory({message: "Execution started"}, jobId, executedBy, uid);

    if(!(await updateJobStatus(jobId, 2, executedBy)))
      return;

    const query = {
      "text": 'SELECT public."fnLog_Insert"($1, $2, $3) as logId',
      "values": [1, "One potatoe, two potatoe...", 'kot']
    };

    //TODO - return with errors explanation
    if(!await dbclient.queryPromise(query)){
      log.error(`Failed to execute SQL for job (id=${jobId})`);
      return;
    }

    await logJobHistory({message: "Execution finished"}, jobId, executedBy, uid);
  }
  catch(e) {
    log.error(`Error during execution of job (id=${jobId}): ${e}`);
  }
  finally {
    await updateJobNextRun(jobId, executedBy);
    await updateJobStatus(jobId, 1, executedBy);
  }  
}
executeJob(287, 'system');