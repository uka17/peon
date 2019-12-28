// engines/main.js
const config = require("../../config/config");
const dbclient = require("../tools/db");
const log = require('../../log/dispatcher');
const uuidv4 = require('uuid/v4');
const jobEngine = require('./job');

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
        "values": [tolerance]
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