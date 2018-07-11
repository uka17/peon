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
function validateObject(object, schema) {
    var ajv = new Ajv();
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
            let validationResult = validateObject(element, models.stepSchema);
            if(!validationResult.isValid) 
                return validationResult;
        }
    }
    return {isValid: true};
}
/**
 * Validation of schedule. Returns {isValid: boolean, errorList: error[]} or {isValid: boolean}
 * @param {object[]} scheduleList List of schedules for validation
 */
module.exports.validateScheduleList = (scheduleList) => {
    if(scheduleList) {
        for(i = 0; i < scheduleList.length; i++) {
            let validationResult = validateObject(element, models.scheduleSchema);
            if(!validationResult.isValid) 
                return validationResult;
        }
    }
    return {isValid: true};
}

