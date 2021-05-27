// engines/main.js
const config = require("../../config/config");
const dbclient = require("../tools/db");
const log = require('../../log/dispatcher');
const uuidv4 = require('uuid/v4');
const jobEngine = require('./job');
const labels = require('../../config/message_labels')('en');

var executionLock;

/**
 * Returns Jobs list which should be executed
 * @param {number} tolerance Allowance of job next run searching criteria in minutes (BETWEEN now-tolerance AND now+tolerance)
 * @returns {Promis} Promis which returns list of Job records to be executed or rejects with error in case of error
 */
function getJobListToRun(tolerance) {
  return new Promise((resolve, reject) => {
    try
    {
      if(typeof tolerance !== 'number' || isNaN(parseInt(tolerance)))
        throw new TypeError('tolerance should be a number'); 
      const query = {
        "text": 'SELECT public."fnJob_ToRun"($1) as jobs',
        "values": [100]
      };
      dbclient.query(query, (err, result) => {
        /* istanbul ignore if */
        if (err) {
          reject(new Error(err));
        } else {
          resolve(result.rows[0].jobs);
        }
      });
    }
    catch(err) {
      log.error(`Parameters type mismatch. Stack: ${err}`);              
      reject(err);   
    }        
  });
}

/**
 * Creates new entry for Job processor run history
 * @param {string} message Message to log
 * @param {string} createdBy Author of message 
 * @param {?string} uid Session id. Default is `null`
 */
function logRunHistory(message, createdBy, uid = null) {
  const query = {
    "text": 'SELECT public."fnRunHistory_Insert"($1, $2, $3) as logId',
    "values": [message, uid, createdBy]
  };                  

  log.info(`${message}. session: ${uid}`);

  dbclient.query(query, (err, result) => {
    if (err)
      log.error(err);
  }); 
}

/**
 * Main function of Job processor. Searches for a Jobs which should be executed and runs them
 * @param {number} tolerance Allowance of job next run searching criteria in minutes 
 */
async function run(tolerance) {  
  let currentExecutableJobId = null;
  try {
    if(typeof tolerance !== 'number' || isNaN(parseInt(tolerance)))
      throw new TypeError('tolerance should be a number');     
    if(executionLock)
      return;
    executionLock = true;    
    let jobRecordsList = await getJobListToRun(tolerance);    
    if(jobRecordsList !== null) {        
      const uid = uuidv4();
      log.info(`${jobRecordsList.length} job(s) in tolerance area to process`);
      for (let i = 0; i < jobRecordsList.length; i++) {
        const jobRecord = jobRecordsList[i];          
        let executionDateTime = new Date(`${jobRecord.nextRun}Z`);
        let currentDateTime = new Date(Date.now());
        if(currentDateTime >= executionDateTime) {
          logRunHistory(`Starting execution of job (id=${jobRecord.id})`, config.systemUser, uid);
          currentExecutableJobId = jobRecord.id;    
          //lock job to avoid second thread
          if(!(await jobEngine.updateJobStatus(jobRecord.id, 2, config.systemUser)))
            break;                          
          jobEngine.executeJob(jobRecord, config.systemUser, uid);
        }
      }
      currentExecutableJobId = null;
    }
    executionLock = false;
  }
  catch (e) {
    log.error(e.stack);
    //unlock job
    if(currentExecutableJobId !== null)
      jobEngine.updateJobStatus(currentExecutableJobId, 1, config.emergencyUser);
    executionLock = false;
  }
}

module.exports.run = run;


/**
 * Reset all jobs statuses
 */
 function resetAllJobsStatuses() {
  return new Promise((resolve, reject) => {
    try {              
      const query = {
        "text": 'SELECT public."fnJob_ResetAll"() as count'
      };
      dbclient.query(query, async (err, result) => {           
        try {
          /*istanbul ignore if*/ 
          if (err) { 
            throw new Error(err);
          } else {    
            resolve(result.rows[0].count);
          }
        }            
        catch(e) /*istanbul ignore next*/ {        
          log.error(`Failed to reset jobs statuses with query ${query}. Stack: ${e}`);        
          reject(e);
        }
      });
    }
    catch(err) {
      log.error(`Reset job list statuses failed. Stack: ${err}`);              
      reject(err);   
    }  
  });
 }
 module.exports.resetAllJobsStatuses = resetAllJobsStatuses;
 
/**
 * Finds all active jobs (not in 'Executing' state, enabled and not deleted) and calculates next run date-time for them
 */
 function updateOverdueJobs() {
  return new Promise((resolve, reject) => {
    try {     
      const query = {
        "text": 'SELECT public."fnJob_SelectAllOverdue"() as jobs'
      };
      dbclient.query(query, async (err, result) => {  
        try {
          /*istanbul ignore if*/ 
          if (err) {
            throw new Error(err);
          } else {
          /* istanbul ignore if */
            if(result.rows[0].jobs == null) {
              resolve(null);
            }
            else {
              let updatedCounter = 0;
              for (let index = 0; index < result.rows[0].jobs.length; index++) {
                const element = result.rows[0].jobs[index];
                let jobAssesmentResult = jobEngine.calculateNextRun(element.job);
                /* istanbul ignore if */
                if(!jobAssesmentResult.isValid)
                  throw new Error(jobAssesmentResult.errorList);
                else {
                  await jobEngine.updateJobNextRun(element.id, jobAssesmentResult.nextRun.toUTCString());
                  await jobEngine.logJobHistory({ message: labels.job.jobNextRunUpdated, level: 2 }, element.id, config.systemUser, null); 
                  updatedCounter++;                  
                }
              }              
              resolve(updatedCounter);
            }
          } 
        }            
        catch(e) /*istanbul ignore next*/ {        
          log.error(`Failed to get job list with query ${query}. Stack: ${e}`);              
          reject(e);
        }         
      });
    }
    catch(err) {
      log.error(`Failed to recalculate next run for outdated jobs. Stack: ${err}`);              
      reject(err);   
    }
  });
}

module.exports.updateOverdueJobs = updateOverdueJobs;