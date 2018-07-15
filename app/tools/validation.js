// utools/validation.js
var mongo = require('mongodb');
var utools = require('../tools/utools');
var models = require('../models/app_models');
const config = require('../../config/config');
const messageBox = require('../../config/message_labels');
var Ajv = require('ajv');

/**
 * Validation of object accordingly schema. Returns {isValid: boolean, errorList: error[]} or {isValid: boolean} 
 * @param {object} object Object for validation
 * @param {json} schema Schema for object validation
 */
function validateObject(object, schema, extraSchemaList) {
    var ajv = new Ajv();
    if(extraSchemaList)
        extraSchemaList.forEach(function(e) { ajv.addSchema(e) }); 
    var validate = ajv.compile(schema);
    var valid = validate(object);
    if (!valid) {
        return {isValid: false, errorList: ajv.errorsText(validate.errors)};
    }
    else
        return {isValid: true};
}
module.exports.validateObject = validateObject;
/**
 * Validation of job. Returns {isValid: boolean, errorList: error[]} or {isValid: boolean} 
 * @param {object} job List of steps for validation
 */
module.exports.validateJob = (job) => {
    models.jobSchema['required'] = models.jobSchemaRequired; 
    return validateObject(job, models.jobSchema);
}
/**
 * Validation of step. Returns {isValid: boolean, errorList: error[]} or {isValid: boolean} 
 * @param {object[]} stepList List of steps for validation
 */
module.exports.validateStepList = (stepList) => {
    if(stepList) {
        models.stepSchema['required'] = models.stepSchemaRequired; 
        for(i = 0; i < stepList.length; i++) {
            let validationResult = validateObject(stepList[i], models.stepSchema);
            if(!validationResult.isValid) 
                return validationResult;
        }
    }
    return {isValid: true};
}
/**
 * Validation of schedule including logical validation (e.g. hours<24 and minutes<60 ). Returns {isValid: boolean, errorList: error[]} or {isValid: boolean}
 * @param {object[]} scheduleList List of schedules for validation
 */
module.exports.validateScheduleList = (scheduleList) => {
    if(scheduleList) {
        for(let i = 0; i < scheduleList.length; i++) {
            let validationResult = validateObject(scheduleList[i], models.scheduleSchema, [models.scheduleSchemaDaily]);
            if(!validationResult.isValid) 
                return validationResult;
        }
    }
    return {isValid: true};
}
/**
 * Validates time value. returns TRUE in case if parameter is correct time value
 * @param {string} time Time value to validate in format hh:mm:ss
 * @returns boolean
 */
module.exports.timeIsValid = (time) => {
    return /^([0-1][0-9]|2[0-3]):([0-5][0-9]):([0-5][0-9])$/.test(time);
}
/**
 * Validates date-time value. Returns TRUE in case if parameter is correct date-time value.
 * Correct data-time value should be date and UTC time accordingly ISO Dates (Date-Time) format YYYY-MM-DDTHH:MM:SSZ
 * Example: 2015-03-25T12:00:00Z
 * @param {string} date Date-time value to validate 
 */
module.exports.dateTimeIsValid = (dateTime) => {
    //TODO bis sextus and 30-31
    let convertedDateTime = new Date(dateTime);
    return convertedDateTime instanceof Date && !isNaN(convertedDateTime);; 
}

