// utools/validation.js
var mongo = require('mongodb');
var utools = require('../tools/utools');
var models = require('../models/app_models');
const config = require('../../config/config');
const messageBox = require('../../config/message_labels');
var Ajv = require('ajv');

/**
 * Validation of object accordingly schema. Returns validation anyway and validation error list in case of error 
 * @param {object} object Object for validation
 * @param {string} schema JSON schema for object validation
 * @returns {{isValid: boolean, errorList: string[]}|{isValid: boolean}} Result of validation and (in case of failure) error list
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
 * Validation of job. Returns validation result anyway and validation error list in case of error 
 * @param {object} job List of steps for validation
 * @returns {{isValid: boolean, errorList: string[]}|{isValid: boolean}} Result of validation and (in case of failure) error list
 */
module.exports.validateJob = (job) => {
    models.jobSchema['required'] = models.jobSchemaRequired; 
    return validateObject(job, models.jobSchema);
}
/**
 * Validation of step list. Returns validation result anyway and validation error list in case of error. 
 * Checks all items. Result is valid only in case is all list is valid 
 * @param {object[]} stepList List of steps for validation
 * @returns {{isValid: boolean, errorList: string[]}|{isValid: boolean}} Result of validation and (in case of failure) error list
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
/** Validation of schedule list. Returns validation result anyway and validation error list in case of error 
* Checks all items. Result is valid only in case is all list is valid
* @param {object[]} scheduleList List of schedules for validation
* @returns {{isValid: boolean, errorList: string[]}|{isValid: boolean}} Result of validation and (in case of failure) error list
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
 * Validates time value. Returns TRUE in case if parameter is correct time value
 * @param {string} time Time value to validate in format hh:mm:ss
 * @returns {boolean} Result of validation
 */
module.exports.timeIsValid = (time) => {
    return /^([0-1][0-9]|2[0-3]):([0-5][0-9]):([0-5][0-9])$/.test(time);
}
/**
 * Validates date-time value. Returns TRUE in case if parameter is correct date-time value.
 * Correct data-time value should be date and UTC time accordingly ISO Dates (Date-Time) format YYYY-MM-DDTHH:MM:SSZ
 * Example: 2015-03-25T12:00:00Z
 * @param {string} date Date-time value to validate 
 * @returns {boolean} Result of validation
 */
module.exports.dateTimeIsValid = (dateTime) => {
    //TODO bis sextus and 30-31
    let convertedDateTime = new Date(dateTime);
    return convertedDateTime instanceof Date && !isNaN(convertedDateTime);; 
}

