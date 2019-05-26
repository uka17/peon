// engine/main.js
var util = require("../tools/util");
const config = require("../../config/config");
const dbclient = require("../tools/db");
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
    executionLock = true;
    let jobList = await getJobListToRun(tolerance);    
    console.log(jobList.length);
    executionLock = false;
}

module.exports.run = run;
