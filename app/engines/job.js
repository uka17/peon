/* eslint-disable no-unused-vars */
/* eslint-disable no-case-declarations */
/* eslint-disable no-prototype-builtins */
// engines/job.js
const validation = require("../tools/validation");
const schedulator = require("schedulator");
const util = require('../tools/util');
const dbclient = require("../tools/db");
const log = require('../../log/dispatcher');
const stepEngine = require('./step');
const labels = require('../../config/message_labels')('en');

/**
 * Returns job count accordingly to filtering
 * @param {string} filter Filter will be applied to `name` and `description` columns
 * @returns {Promise} Promise which resolves with numeber of `job` objects in case of success, `null` if job list is empty and rejects with error in case of failure
 */
function getJobCount(filter) {
  return new Promise((resolve, reject) => {
    const query = {
      "text": 'SELECT public."fnJob_Count"($1) as count',
      "values": [filter]
    };
    dbclient.query(query, (err, result) => {  
      /* istanbul ignore if */
      if (err) {
        log.error(`Failed to get job count (params=${query.values}). Stack: ${err.stack}`);     
        reject(err);
      } else {
        /* istanbul ignore if */
        if(result.rows[0].count == null) {
          resolve(null);
        }
        else
          resolve(result.rows[0].count);
      } 
    });
  });
}
module.exports.getJobCount = getJobCount;

/**
 * Returns job list accordingly to filtering, sorting and page order and number
 * @param {string} filter Filter will be applied to `name` and `description` columns
 * @param {string} sortColumn Name of sorting column
 * @param {string} sortOrder Sorting order (`asc` or `desc`)
 * @param {number} perPage Number of record per page
 * @param {number} page Page number
 * @returns {Promise} Promise which resolves with list of `job` objects in case of success, `null` if job list is empty and rejects with error in case of failure 
 */
function getJobList(filter, sortColumn, sortOrder, perPage, page) {
  return new Promise((resolve, reject) => {
    const query = {
      "text": 'SELECT public."fnJob_SelectAll"($1, $2, $3, $4, $5) as jobs',
      "values": [filter, sortColumn, sortOrder, perPage, page]
    };
    dbclient.query(query, (err, result) => {  
      /* istanbul ignore if */
      if (err) {
        log.error(`Failed to get job list (params=${query.values}). Stack: ${err.stack}`);             
        reject(err);
      } else {
        /* istanbul ignore if */
        if(result.rows[0].jobs == null) {
          resolve(null);
        }
        else
          resolve(result.rows[0].jobs);
      } 
    });
  });
}
module.exports.getJobList = getJobList;

/**
 * Returns job by id
 * @param {number} jobId Id of job
 * @returns {Promise} Promise which resolves with `job` in case of success, `null` if job is not found by `id` and rejects with error in case of failure
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
        log.error(`Failed to get job (jobId=${jobId}). Stack: ${err.stack}`);                             
        reject(err);
      } else {
        /* istanbul ignore if */
        if(result.rows[0].job == null) {
          resolve(null);
        }
        else
          resolve(result.rows[0].job);
      } 
    });
  });
}
module.exports.getJob = getJob;

/**
 * Creates new job in DB
 * @param {Object} job Job object to be created in DB
 * @param {string?} createdBy User who creates job
 * @returns {Promise} Promise which resolves with just created job with `id` in case of success and rejects with error in case of failure
 */
function createJob(job, createdBy) {
  return new Promise((resolve, reject) => {
    const query = {
      "text": 'SELECT public."fnJob_Insert"($1, $2) as id',
      "values": [job, createdBy]
    };
    dbclient.query(query, async (err, result) => {           
      try {
        /* istanbul ignore if */
        if (err) { 
          log.error(`Failed to create job with content ${job}. Stack: ${err.stack}`);                     
          reject(err);
        } else {
          job.id = result.rows[0].id;
          resolve(job);
        }
      }            
      catch(e) {        
        /* istanbul ignore next */        
        reject(e);
      }
    });
  });
}
module.exports.createJob = createJob;

/**
 * Updates job in DB by id
 * @param {number} jobId Id of job to be updated
 * @param {Object} job Job object to be updated with
 * @param {string} updatedBy User who updates job
 * @returns {Promise} Promise which resolves with number of updated rows in case of success and rejects with error in case of failure 
 */
function updateJob(jobId, job, updatedBy) {
  return new Promise((resolve, reject) => {
    const query = {
      "text": 'SELECT public."fnJob_Update"($1, $2, $3, $4) as count',
      "values": [jobId, job, job.nextRun.toUTCString(), updatedBy]
    };
    dbclient.query(query, async (err, result) => {           
      try {
        /* istanbul ignore if */
        if (err) { 
          log.error(`Failed to update job (jobId=${jobId}) with content ${job}. Stack: ${err.stack}`);                     
          reject(err);
        } else {    
          resolve(result.rows[0].count);
        }
      }
      catch(e) {
        /* istanbul ignore next */        
        reject(e);
      }
    });
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
    const query = {
      "text": 'SELECT public."fnJob_Delete"($1, $2) as count',
      "values": [jobId, deletedBy]
    };
    dbclient.query(query, async (err, result) => {           
      try {
        /* istanbul ignore if */
        if (err) {
          log.error(`Failed to delete job (jobId=${jobId}). Stack: ${err.stack}`);           
          reject(err);
        } else {    
          resolve(result.rows[0].count);
        }
      }
      catch(e) {
        /* istanbul ignore next */
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
 * @property {string=} nextRun If `isValid` is `true` represents next run `date-time`
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
        /* istanbul ignore if */
        if (nextRunList.length == 0)
          return {
            "isValid": false,
            "errorList": labels.schedule.nextRunCanNotBeCalculated
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
    /* istanbul ignore next */
    log.error(`Failed to calculate next run for job (jobId=${job.id}). Stack: ${e.stack}`);
    /* istanbul ignore next */
    return {"isValid": false, "errorList": e.message};
  }
}
module.exports.calculateNextRun = calculateNextRun;
/**
 * Calculates and save job next run
 * @param {number} jobId Job id
 * @param {string} nextRun `date-time` of job next run 
 * @param {string} executedBy Author of change
 * @returns {Promise} Promise which returns `true` in case of success and `false` in case of failure 
 */
function updateJobNextRun(jobId, nextRun, executedBy) {
  //TODO
  //check input parameters
  // eslint-disable-next-line no-async-promise-executor
  return new Promise(async (resolve, reject) => {
    const query = {
      "text": 'SELECT public."fnJob_UpdateNextRun"($1, $2, $3) as count',
      "values": [jobId, nextRun, executedBy]
    };
    dbclient.query(query, (err, result) => {     
      /* istanbul ignore if */      
      if (err) {
        log.error(`Failed to update job (jobId=${jobId}) next run date-time with ${nextRun}. Stack: ${err.stack}`);
        reject(false);
      } else {
        resolve(true);
      } 
    });
  });
}
module.exports.updateJobNextRun = updateJobNextRun;

/**
 * Changes job last run result. Last run date-time will be updated with current timestamp.
 * @param {number} jobId Job id
 * @param {number} runResult Job run result. `true` - success, `false` - failure
 * @param {string} executedBy Author of change 
 * @returns {Promise} Promise which returns `true` in case of success and `false` in case of failure
 */
function updateJobLastRun(jobId, runResult, executedBy) {
  return new Promise((resolve, reject) => {
    const query = {
      "text": 'SELECT public."fnJob_UpdateLastRun"($1, $2, $3) as updated',
      "values": [jobId, runResult, executedBy]
    };                  

    // eslint-disable-next-line no-unused-vars
    dbclient.query(query, (err, result) => {
      /* istanbul ignore if */      
      if (err) {
        log.error(`Failed to change job last run result (jobId=${jobId}) to '${runResult}'. Stack: ${err.stack}`);
        reject(false);
      }
      else
        resolve(true);
    }); 
  });
}
module.exports.updateJobLastRun = updateJobLastRun;

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

    // eslint-disable-next-line no-unused-vars
    dbclient.query(query, (err, result) => {
      /* istanbul ignore if */      
      if (err) {
        log.error(`Failed to change job (jobId=${jobId}) status to '${status}'. Stack: ${err.stack}`);
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

    // eslint-disable-next-line no-unused-vars
    dbclient.query(query, (err, result) => {
      /* istanbul ignore if */
      if (err) {
        log.error(`Failed to insert job history (jobId=${jobId}). Stack: ${err.stack}`);
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
    let jobExecutionResult = true;
    if(job !== null) {
      if(job.hasOwnProperty("steps") && job.steps.length > 0) {
        //TODO sort steps in right order
        step_loop:
        for (let i = 0; i < job.steps.length; i++) {
          const step = job.steps[i];
          await logJobHistory({ message: labels.execution.executingStep(step.name), level: 2 }, jobId, executedBy, uid);
          let stepExecution = await stepEngine.execute(step);
          //log execution result
          if(stepExecution.result) {
            await logJobHistory(
              { 
                message: labels.execution.stepExecuted(step.name),
                rowsAffected: stepExecution.affected, 
                level: 2 
              }, 
              jobId, executedBy, uid);
            //take an action based on execution result
            switch(step.onSucceed) {
            case 'gotoNextStep':
              break;          
            case 'quitWithSuccess':               
              break step_loop;
            case 'quitWithFailure': 
              jobExecutionResult = false;
              break step_loop;                     
            }              
          } else {
            await logJobHistory(
              { 
                message: labels.execution.stepFailed(step.name),
                error: stepExecution.error, 
                level: 0 
              }, 
              jobId, executedBy, uid);
            //TODO repeat attempt

            //take an action based on execution result
            switch(step.onFailure) {
            case 'gotoNextStep':
              break;          
            case 'quitWithSuccess': 
              jobExecutionResult = true;            
              break step_loop;
            case 'quitWithFailure':
              jobExecutionResult = false;               
              break step_loop;                     
            }              
          }
        }
      } else {
        log.warn(`No step list found for job (jobId=${jobId})`);
      }
      if(jobExecutionResult) {
        log.info(`Job (jobId=${jobId}) successfully finsihed. usid: ${uid}`);
        await logJobHistory({ message: labels.execution.jobFinished, level: 2 }, jobId, executedBy, uid);        

      } else {
        log.info(`Job (jobId=${jobId}) failed. usid: ${uid}`);
        await logJobHistory({ message: labels.execution.jobFinished, level: 2 }, jobId, executedBy, uid);        
      }      

      let jobAssesmentResult = calculateNextRun(job);  
      /* istanbul ignore if */
      if(!jobAssesmentResult.isValid) {
        await updateJobNextRun(jobId, null, executedBy);
      }        
      else {
        await updateJobNextRun(jobId, jobAssesmentResult.nextRun.toUTCString(), executedBy);
      }                
    } else
      log.error(`Failed to get job (jobId=${jobId}) for execution`);   
  }
  catch(e) {
    log.error(`Error during execution of job (jobId=${jobId}). Stack: ${e.stack}`);
  }
  finally {
    await updateJobStatus(jobId, 1, executedBy);
  }  
}

module.exports.executeJob = executeJob;