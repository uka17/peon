// engines/main.js
var util = require("../tools/util");
const config = require("../../config/config");
const dbclient = require("../tools/db");
const log = require('../../log/dispatcher');
const uuidv4 = require('uuid/v4');
const jobEngine = require('./job');

var executionLock;

run(1);

/**
 * Returns jobs list which should be executed
 * @param {number} tolerance Allowance of job next run searching criteria in minutes (BETWEEN now-tolerance AND now+tolerance)
 * @returns {Object[]} List of job objects to be executed
 */
function getJobListToRun(tolerance) {
  return new Promise((resolve, reject) => {
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
  });
}

/**
 * Creates new entry for run history table
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
 * Searches for a jobs which should be executed and runs them
 * @param {number} tolerance Allowance of job next run searching criteria in minutes 
 */
async function run(tolerance) {  
  let currentExecutableJobId = null;
  try {
    if(executionLock)
      return;
    executionLock = true;    
    let jobList = await getJobListToRun(tolerance);    
    if(jobList !== null) {        
        const uid = uuidv4();        
        logRunHistory(`${jobList.length} job(s) in tolerance area to process`, config.systemUser, uid);
        for (let i = 0; i < jobList.length; i++) {
            const job = jobList[i];          
            let executionDateTime = new Date(`${job.nextRun}Z`);
            let currentDateTime = new Date(Date.now());
            if(currentDateTime >= executionDateTime) {
              logRunHistory(`Starting execution of job (id=${job.id})`, config.systemUser, uid);
              currentExecutableJobId = job.id;    
              //lock job to avoid second thread
              if(!(await jobEngine.updateJobStatus(job.id, 2, config.systemUser)))
                break;                          
              jobEngine.executeJob(job.id, config.systemUser, uid);
            }
        }
        currentExecutableJobId = null;
    }
    executionLock = false;
  }
  catch (e) {
    log.error(e.stack);
    if(currentExecutableJobId === null)
      jobEngine.updateJobStatus(currentExecutableJobId, 1, config.emergencyUser);
    executionLock = false;
  }
}

module.exports.run = run;

run(1);