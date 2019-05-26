// engine/job.js
var validation = require("../tools/validation");
var schedulator = require("schedulator");
var util = require('../tools/util')
const messageBox = require('../../config/message_labels');

/**
 * Validates job and calculates next run date and time for it
 * @param {object} job Job which should be used for calculation
 * @return {object} {isValid: boolean, errorList(optional): string, nextRun(optional): date-time}
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