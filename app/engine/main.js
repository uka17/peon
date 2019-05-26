// engine/main.js
var util = require("../tools/util");
const config = require("../../config/config");
const dbclient = require("../tools/db");
const jobEngine = require("./job");
const log = require('../../log/dispatcher');

var executionLock;

run(100);

/**
 * Returns jobs list which should be executed
 * @param {integer} tolerance Allowance of job next run searching criteria in minutes (BETWEEN now-tolerance AND now+tolerance)
 * @returns {object[]} List of job objects to be executed
 */
function getJobListToRun(tolerance) {
  try {
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
  } catch (e) {
    /* istanbul ignore next */
    util.handleServerException(e, config.user, dbclient, res);
  }
}

/**
 * Searches for a jobs which should be executed and runs them
 * @param {integer} tolerance Allowance of job next run searching criteria in minutes 
 */
async function run(tolerance) {  
    if(executionLock)
        return;
    executionLock = true;    
    let jobList = await getJobListToRun(tolerance);    
    if(jobList !== null) {
        //TODO normal ID
        const uid = `f${(+new Date).toString(16)}`;
        jobEngine.logRunHistory(`'${uid}' session has started`, config.user);                
        jobEngine.logRunHistory(`'${jobList.length}' job(s) to process`, config.user);
        for (let i = 0; i < jobList.length; i++) {
            const job = jobList[i];
            log.info(job.id);
        }
        jobEngine.logRunHistory(`'${uid}' session has ended`, config.user);
    }
    executionLock = false;
}

module.exports.run = run;
