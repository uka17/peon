/* eslint-disable no-unused-vars */
/* eslint-disable no-case-declarations */
/* eslint-disable no-prototype-builtins */
// engines/job.js
const validation = require("../tools/validation");
const schedulator = require("schedulator");
const util = require('../tools/util');
const config = require('../../config/config');
const dbclient = require("../tools/db");
const log = require('../../log/dispatcher');
const stepEngine = require('./step');
const labels = require('../../config/message_labels')('en');

/**
 * Returns job count accordingly to filtering
 * @param {string} filter Filter will be applied to `name` and `description` columns
 * @returns {Promise} Promise which resolves with numeber of `job` objects in case of success and rejects with error in case of failure
 */
function getJobCount(filter) {
  return new Promise((resolve, reject) => {
    const query = {
      "text": 'SELECT public."fnJob_Count"($1) as count',
      "values": [filter]
    };
    dbclient.query(query, (err, result) => {  
      try {
        /* istanbul ignore if */
        if (err) {
          throw new Error(err);
        } else {
          resolve(result.rows[0].count);
        } 
      }            
      catch(e) {        
        /* istanbul ignore next */
        log.error(`Failed to get job count with query ${query}. Stack: ${e}`);        
        /* istanbul ignore next */
        reject(e);
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
      try {
        if (err) {
          throw new Error(err);
        } else {
        /* istanbul ignore if */
          if(result.rows[0].jobs == null) {
            resolve(null);
          }
          else
            resolve(result.rows[0].jobs);
        } 
      }            
      catch(e) {        
        log.error(`Failed to get job list with query ${query}. Stack: ${e}`);              
        reject(e);
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
      try {
        if (err) {
          throw new Error(err);
        } else {
        /* istanbul ignore if */
          if(result.rows[0].job == null) {
            resolve(null);
          }
          else
            resolve(result.rows[0].job);
        } 
      }            
      catch(e) {        
        log.error(`Failed to get job with query ${query}. Stack: ${e}`);              
        reject(e);
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
        if (err) { 
          throw new Error(err);
        } else {  
          let newBornJob = await module.exports.getJob(result.rows[0].id);        
          resolve(newBornJob);
        }
      }            
      catch(e) {        
        log.error(`Failed to create job with content ${job}. Stack: ${e}`);        
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
    try {
      const query = {
        "text": 'SELECT public."fnJob_Update"($1, $2, $3, $4) as count',
        "values": [jobId, job, job.nextRun.toUTCString(), updatedBy]
      };
      dbclient.query(query, async (err, result) => {           
        try {
          if (err) { 
            throw new Error(err);
          } else {    
            resolve(result.rows[0].count);
          }
        }            
        catch(e) {        
          log.error(`Failed to update job with query ${query}. Stack: ${e}`);        
          reject(e);
        }
      });
    }
    catch(ee) {
      log.error(`Failed to create query for job update with job ${job} and jobId ${job}. Stack: ${ee}`);        
      reject(ee);
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
    const query = {
      "text": 'SELECT public."fnJob_Delete"($1, $2) as count',
      "values": [jobId, deletedBy]
    };
    dbclient.query(query, async (err, result) => {           
      try {
        if (err) {
          throw new Error(err);
        } else {    
          resolve(result.rows[0].count);
        }
      }            
      catch(e) {        
        log.error(`Failed to delete job with query ${query}. Stack: ${e}`);        
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
            if (job.schedules[i].enabled) {
              let nextRun = schedulator.nextOccurrence(job.schedules[i]);
              if (nextRun.result != null) 
                nextRunList.push(nextRun.result);
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
    log.error(`Failed to calculate next run for job (jobId=${job.id}). Stack: ${e}`);
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
  return new Promise((resolve, reject) => {
    const query = {
      "text": 'SELECT public."fnJob_UpdateNextRun"($1, $2, $3) as count',
      "values": [jobId, nextRun, executedBy]
    };
    dbclient.query(query, (err, result) => {     
      try {
        if (err) {
          throw new Error(err);
        } else {
          resolve(true);
        } 
      }            
      catch(e) {        
        log.error(`Failed to update job next run with query ${query}. Stack: ${e}`);        
        reject(e);
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
      try { 
        if (err) {
          throw new Error(err);
        }
        else
          resolve(true);
      }            
      catch(e) {        
        log.error(`Failed to update job last run with query ${query}. Stack: ${e}`);        
        reject(e);
      }  
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
      try {
        if (err) {
          throw new Error(err);
        }
        else
          resolve(true);
      }
      catch(e) {        
        log.error(`Failed to update job status with query ${query}. Stack: ${e}`);        
        reject(e);
      }      
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
 * @returns {Promise} Promise which returns `true` in case of success and error in case of failure
 */
function logJobHistory(message, jobId, createdBy, uid) {
  return new Promise((resolve, reject) => {
    const query = {
      "text": 'SELECT public."fnJobHistory_Insert"($1, $2, $3, $4) as updated',
      "values": [message, uid, jobId, createdBy]
    };                  

    // eslint-disable-next-line no-unused-vars
    dbclient.query(query, (err, result) => {
      try {
        if (err) {
          throw new Error(err);
        }
        else
          resolve(true); 
      }
      catch(e) {        
        log.error(`Failed to add record to log job history with query ${query}. Stack: ${e}`);        
        reject(e);
      }      
    }); 
  });
}
module.exports.logJobHistory = logJobHistory;

/**
 * Executes job
 * @param {Object} jobRecord Job record for execution
 * @param {string} executedBy User who is executing job
 * @param {?string} uid Session id. Default is `null`  
 */
async function executeJob(jobRecord, executedBy, uid) {
  try {
    if(jobRecord === null || jobRecord === undefined)
      throw new Error(`Failed to get job (jobRecord=${jobRecord}) for execution`);

    await logJobHistory({ message: labels.execution.jobStarted(jobRecord.id), level: 2 }, jobRecord.id, executedBy, uid);
    let job = jobRecord.job;
    let jobExecutionResult = true;
    if(job.hasOwnProperty("steps") && job.steps.length > 0) {
      //TODO sort steps in right order
      step_loop:
      for (let stepIndex = 0; stepIndex < job.steps.length; stepIndex++) {
        const step = job.steps[stepIndex];
        await logJobHistory({ message: labels.execution.executingStep(step.name), level: 2 }, jobRecord.id, executedBy, uid);
        let stepExecution = await stepEngine.execute(step);
        //log execution result
        if(stepExecution.result) {
          await logJobHistory(
            { 
              message: labels.execution.stepExecuted(step.name),
              rowsAffected: stepExecution.affected, 
              level: 2 
            }, 
            jobRecord.id, executedBy, uid);
          //take an action based on execution result
          switch(step.onSucceed) {
          case 'gotoNextStep':
            break;          
          case 'quitWithSuccess': 
            jobExecutionResult = true;              
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
            jobRecord.id, executedBy, uid);
          let repeatSucceeded = false;
          //There is a requierement to try to repeat step in case of failure              
          if(step.retryAttempts.number > 0) {
            attempt_loop:
            for (let attempt = 0; attempt < step.retryAttempts.number; attempt++) {
              await logJobHistory({ message: labels.execution.repeatingStep(step.name, attempt + 1, step.retryAttempts.number), level: 2 }, jobRecord.id, executedBy, uid);
              let repeatExecution = await stepEngine.delayedExecute(step, step.retryAttempts.interval);
              if(repeatExecution.result) {
                await logJobHistory(
                  { 
                    message: labels.execution.stepRepeatSuccess(step.name, attempt + 1),
                    rowsAffected: stepExecution.affected, 
                    level: 2 
                  }, 
                  jobRecord.id, executedBy, uid);
                //take an action based on execution result
                switch(step.onSucceed) {
                case 'gotoNextStep':
                  repeatSucceeded = true;
                  break attempt_loop;          
                case 'quitWithSuccess':         
                  jobExecutionResult = true;                        
                  break step_loop;
                case 'quitWithFailure': 
                  jobExecutionResult = false;
                  break step_loop;                     
                }                                
              } else {
                await logJobHistory(
                  { 
                    message: labels.execution.stepRepeatFailure(step.name, attempt + 1),
                    error: stepExecution.error, 
                    level: 0 
                  }, 
                  jobRecord.id, executedBy, uid);
              } 
            }            
          }
          if(!repeatSucceeded) {
            //all aditional attempts failed
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
      }
    } else {
      log.warn(`No step list found for job (jobRecord.id=${jobRecord.id})`);
      await logJobHistory({ message: labels.execution.jobNoSteps(jobRecord.id), level: 0 }, jobRecord.id, executedBy, uid);
    }
    await updateJobLastRun(jobRecord.id, jobExecutionResult, executedBy);
    if(jobExecutionResult) {
      log.info(`Job (jobRecord.id=${jobRecord.id}) successfully finsihed. session: ${uid}`);
      await logJobHistory({ message: labels.execution.jobSuccessful(jobRecord.id), level: 2 }, jobRecord.id, executedBy, uid);        

    } else {
      log.info(`Job (jobRecord.id=${jobRecord.id}) failed. session: ${uid}`);
      await logJobHistory({ message: labels.execution.jobFailed(jobRecord.id), level: 0 }, jobRecord.id, executedBy, uid);        
    }      

    let jobAssesmentResult = calculateNextRun(job);  
    if(!jobAssesmentResult.isValid) {
      await updateJobNextRun(jobRecord.id, null, executedBy);
    }        
    else {
      await updateJobNextRun(jobRecord.id, jobAssesmentResult.nextRun.toUTCString(), executedBy);
    }                
 
  }
  catch(e) {
    log.error(`Error during execution of job (jobRecord=${jobRecord}). Stack: ${e}`);
  }
  finally {
    if(jobRecord !== null && jobRecord !== undefined)
      await updateJobStatus(jobRecord.id, 1, executedBy);
  }  
}
module.exports.executeJob = executeJob;

/*
async function test() {
  await executeJob(await getJob(768), config.testUser);
}
test();
*/
