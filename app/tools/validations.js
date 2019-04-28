// utools/validations.js
//Functions-helpers for validating differen objects
var mongo = require('mongodb');
var utools = require('../tools/utools');
var models = require('../models/app_models.json');
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
 * @param {object} job Job object for validation
 * @returns {{isValid: boolean, errorList: string[]}|{isValid: boolean}} Result of validation and (in case of failure) error list
 */
module.exports.validateJob = (job) => {
    models.jobSchema['required'] = models.jobSchemaRequired; 
    return validateObject(job, models.jobSchema);
}

/**
 * Validation of connection. Returns validation result anyway and validation error list in case of error 
 * @param {object} connection Connection object for validation
 * @returns {{isValid: boolean, errorList: string[]}|{isValid: boolean}} Result of validation and (in case of failure) error list
 */
module.exports.validateConnection = (connection) => {
    models.connectionSchema['required'] = models.connectionSchemaRequired; 
    return validateObject(connection, models.connectionSchema);
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
        for(let i = 0; i < stepList.length; i++) {
            let validationResult = validateObject(stepList[i], models.stepSchema);
            if(!validationResult.isValid) 
                return validationResult;
        }
    }
    return {isValid: true};
}

