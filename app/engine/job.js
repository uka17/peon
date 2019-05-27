// engine/job.js
var validation = require("../tools/validation");
var schedulator = require("schedulator");
var util = require('../tools/util')
const dbclient = require("../tools/db");
const messageBox = require('../../config/message_labels');
const log = require('../../log/dispatcher');

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
  let validationequence = ["job", "steps", "notifications", "schedules"];
  let jobValidationResult;
  for (i = 0; i < validationequence.length; i++) {
    switch (validationequence[i]) {
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
    if (!jobValidationResult.isValid) return jobValidationResult;
  }
  return jobValidationResult;
}
module.exports.calculateNextRun = calculateNextRun;

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

  dbclient.query(query, (err, result) => {
      if (err)
        log.error(err);
  }); 
}
module.exports.logRunHistory = logRunHistory;

/**
 * Changes job status
 * @param {number} id Job id
 * @param {number} status Status id. `1` - idle, `2` - execution
 * @param {string} modifiedBy Author of change 
 * @returns {Promise} Promise which returns `true` in case of success and `false` in case of failure
 */
function changeJobStatus(id, status, modifiedBy) {
  return new Promise((resolve, reject) => {
    const query = {
      "text": 'SELECT public."fnJob_ChangeStatus"($1, $2, $3) as updated',
      "values": [id, status, modifiedBy]
    };                  

    dbclient.query(query, (err, result) => {
        if (err) {
          log.error(`Error while changing job (id=${id}) status to '${status}'`);
          reject(false);
        }
        else
          resolve(result.rows[0].updated);
    }); 
  });
}