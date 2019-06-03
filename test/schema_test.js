var assert  = require('chai').assert;
var request = require('request');
var Ajv = require('ajv');
var messageBox = require('../config/message_labels.js');
var schema = require('../app/models/app_models.json');
const config = require('../config/config.js');
var testData = require('./test_data');

//test data preparation
var testJob = testData.jobOK;
var testStep = testData.stepOK;
//---
/**
 * Returns result of object validation across one or several nested schemas
 * @param {object} testData Object to be validated
 * @param {object} schema Schema across which object should be validated
 * @param {object[]=} extraSchemaList Any extra schema list which should be used for validation
 * @returns {boolean} Result of object validation
 */
function DataVsSchemaResult(testData, schema, extraSchemaList) {
    //TODO: to be optimized with removeSchema(/.*/)
    var ajv = new Ajv();
    if(extraSchemaList)
        extraSchemaList.forEach(function(e) { ajv.addSchema(e) }); 
    let validate = ajv.compile(schema);
    return validate(testData);
}
/**
 * Returns result of object validation across one or several nested schemas
 * @param {object} testData Object to be validated
 * @param {object} schema Schema across which object should be validated
 * @param {object[]=} extraSchemaList Any extra schema list which should be used for validation
 * @returns {string} List of errors
 */
function DataVsSchemaErrors(testData, schema, extraSchema) {
    //TODO: to be optimized with removeSchema(/.*/)
    var ajv = new Ajv();
    if(extraSchema)
        extraSchema.forEach(function(e) { ajv.addSchema(e) }); 
    let validate = ajv.compile(schema);
    validate(testData);
    return ajv.errorsText(validate.errors);
}

describe('schema validation', function() {
    describe('job', function() {
        it('initial validation. OK', function(done) {                            
            assert.equal(DataVsSchemaResult(testJob, schema.jobSchema), true);
            done();
        })
        it('incorrect "name" type', function(done) {    
            let nJob = JSON.parse(JSON.stringify(testJob));
            nJob.name = 1;

            assert.equal(DataVsSchemaResult(nJob, schema.jobSchema), false);
            assert.equal(DataVsSchemaErrors(nJob, schema.jobSchema), 'data.name should be string');
            done();
        })        
        it('incorrect "description" type', function(done) {    
            let nJob = JSON.parse(JSON.stringify(testJob));
            nJob.description = 1;

            assert.equal(DataVsSchemaResult(nJob, schema.jobSchema), false);
            assert.equal(DataVsSchemaErrors(nJob, schema.jobSchema), 'data.description should be string');
            done();
        })     
        it('incorrect "steps" type', function(done) {    
            let nJob = JSON.parse(JSON.stringify(testJob));
            nJob.steps = 1;

            assert.equal(DataVsSchemaResult(nJob, schema.jobSchema), false);
            assert.equal(DataVsSchemaErrors(nJob, schema.jobSchema), 'data.steps should be array');
            done();
        })                 
        it('extra property', function(done) {    
            let nJob = JSON.parse(JSON.stringify(testJob));
            nJob.extra = 1;

            assert.equal(DataVsSchemaResult(nJob, schema.jobSchema), false);
            assert.equal(DataVsSchemaErrors(nJob, schema.jobSchema), 'data should NOT have additional properties');
            done();
        })       
        it('not all properties', function(done) {    
            let nJob = JSON.parse(JSON.stringify(testJob));
            delete nJob.description;
            assert.equal(DataVsSchemaResult(nJob, schema.jobSchema), true);
            done();
        })            
        it('required properties not found', function(done) {    
            let nJob = JSON.parse(JSON.stringify(testJob));
            delete nJob.name;
            schema.jobSchema['required'] = schema.jobSchemaRequired; 
            assert.equal(DataVsSchemaResult(nJob, schema.jobSchema), false);
            assert.equal(DataVsSchemaErrors(nJob, schema.jobSchema), "data should have required property 'name'");
            done();
        })                         
    })
    describe('step', function() {
        it('initial validation. "gotoNextStep". OK', function(done) {                            
            let nStep = JSON.parse(JSON.stringify(testStep));
            nStep.onSucceed = 'gotoNextStep';
            nStep.onFailure = 'gotoNextStep';
            assert.equal(DataVsSchemaResult(nStep, schema.stepSchema), true);
            done();
        })
        it('initial validation. "quitWithSuccess". OK', function(done) {                            
            let nStep = JSON.parse(JSON.stringify(testStep));
            nStep.onSucceed = 'quitWithSuccess';
            nStep.onFailure = 'quitWithSuccess';
            assert.equal(DataVsSchemaResult(nStep, schema.stepSchema), true);
            done();
        })
        it('initial validation. "quitWithFailure". OK', function(done) {                            
            let nStep = JSON.parse(JSON.stringify(testStep));
            nStep.onSucceed = 'quitWithFailure';
            nStep.onFailure = 'quitWithFailure';
            assert.equal(DataVsSchemaResult(nStep, schema.stepSchema), true);
            done();
        })   
        it('initial validation. "gotoStep". OK', function(done) {                            
            let nStep = JSON.parse(JSON.stringify(testStep));
            nStep.onSucceed = {gotoStep: 2};
            nStep.onFailure = {gotoStep: 2};
            assert.equal(DataVsSchemaResult(nStep, schema.stepSchema), true);
            done();
        })  
        it('incorrect "name" type', function(done) {                            
            let nStep = JSON.parse(JSON.stringify(testStep));
            nStep.name = true;
            assert.equal(DataVsSchemaResult(nStep, schema.stepSchema), false);
            assert.equal(DataVsSchemaErrors(nStep, schema.stepSchema), "data.name should be string");            
            done();
        })
        it('incorrect "enabled" type', function(done) {                            
            let nStep = JSON.parse(JSON.stringify(testStep));
            nStep.enabled = 1;
            assert.equal(DataVsSchemaResult(nStep, schema.stepSchema), false);
            assert.equal(DataVsSchemaErrors(nStep, schema.stepSchema), "data.enabled should be boolean");            
            done();
        })      
        it('incorrect "connection" type', function(done) {                            
            let nStep = JSON.parse(JSON.stringify(testStep));
            nStep.connection = true;
            assert.equal(DataVsSchemaResult(nStep, schema.stepSchema), false);
            assert.equal(DataVsSchemaErrors(nStep, schema.stepSchema), "data.connection should be integer");            
            done();
        })      
        it('incorrect "command" type', function(done) {                            
            let nStep = JSON.parse(JSON.stringify(testStep));
            nStep.command = 1;
            assert.equal(DataVsSchemaResult(nStep, schema.stepSchema), false);
            assert.equal(DataVsSchemaErrors(nStep, schema.stepSchema), "data.command should be string");            
            done();
        })  
        it('incorrect "onSucceed" value', function(done) {                            
            let nStep = JSON.parse(JSON.stringify(testStep));
            nStep.onSucceed = 'fuck';
            assert.equal(DataVsSchemaResult(nStep, schema.stepSchema), false);
            assert.equal(DataVsSchemaErrors(nStep, schema.stepSchema), "data.onSucceed should be equal to one of the allowed values, data.onSucceed should be object, data.onSucceed should match exactly one schema in oneOf");            
            done();
        })     
        it('incorrect "onSucceed" type', function(done) {                            
            let nStep = JSON.parse(JSON.stringify(testStep));
            nStep.onSucceed = 1;
            assert.equal(DataVsSchemaResult(nStep, schema.stepSchema), false);
            assert.equal(DataVsSchemaErrors(nStep, schema.stepSchema), "data.onSucceed should be equal to one of the allowed values, data.onSucceed should be object, data.onSucceed should match exactly one schema in oneOf");            
            done();
        })          
        it('extra properties "onSucceed"', function(done) {                            
            let nStep = JSON.parse(JSON.stringify(testStep));
            nStep.onSucceed = {gotoStep: 2, a: 1};
            assert.equal(DataVsSchemaResult(nStep, schema.stepSchema), false);
            assert.equal(DataVsSchemaErrors(nStep, schema.stepSchema), "data.onSucceed should be equal to one of the allowed values, data.onSucceed should NOT have additional properties, data.onSucceed should match exactly one schema in oneOf");            
            done();
        }) 
        it('incorrect "onSucceed-gotoStep" type', function(done) {                            
            let nStep = JSON.parse(JSON.stringify(testStep));
            nStep.onSucceed = {gotoStep: true};
            nStep.onFailure = {gotoStep: 2};
            assert.equal(DataVsSchemaResult(nStep, schema.stepSchema), false);
            assert.equal(DataVsSchemaErrors(nStep, schema.stepSchema), "data.onSucceed should be equal to one of the allowed values, data.onSucceed.gotoStep should be integer, data.onSucceed should match exactly one schema in oneOf");            
            done();
        })      
        it('incorrect minimum "onSucceed-gotoStep"', function(done) {                            
            let nStep = JSON.parse(JSON.stringify(testStep));
            nStep.onSucceed = {gotoStep: 0};
            nStep.onFailure = {gotoStep: 2};
            assert.equal(DataVsSchemaResult(nStep, schema.stepSchema), false);
            assert.equal(DataVsSchemaErrors(nStep, schema.stepSchema), "data.onSucceed should be equal to one of the allowed values, data.onSucceed.gotoStep should be >= 1, data.onSucceed should match exactly one schema in oneOf");            
            done();
        })           
        it('incorrect "onFailure" value', function(done) {                            
            let nStep = JSON.parse(JSON.stringify(testStep));
            nStep.onFailure = 'fuck';
            assert.equal(DataVsSchemaResult(nStep, schema.stepSchema), false);
            assert.equal(DataVsSchemaErrors(nStep, schema.stepSchema), "data.onFailure should be equal to one of the allowed values, data.onFailure should be object, data.onFailure should match exactly one schema in oneOf");            
            done();
        })                  
        it('incorrect "onFailure" type', function(done) {                            
            let nStep = JSON.parse(JSON.stringify(testStep));
            nStep.onFailure = 1;
            assert.equal(DataVsSchemaResult(nStep, schema.stepSchema), false);
            assert.equal(DataVsSchemaErrors(nStep, schema.stepSchema), "data.onFailure should be equal to one of the allowed values, data.onFailure should be object, data.onFailure should match exactly one schema in oneOf");            
            done();
        })                      
        it('extra properties "onFailure"', function(done) {                            
            let nStep = JSON.parse(JSON.stringify(testStep));
            nStep.onFailure = {gotoStep: 2, a: 1};
            assert.equal(DataVsSchemaResult(nStep, schema.stepSchema), false);
            assert.equal(DataVsSchemaErrors(nStep, schema.stepSchema), "data.onFailure should be equal to one of the allowed values, data.onFailure should NOT have additional properties, data.onFailure should match exactly one schema in oneOf");            
            done();
        })               
        it('incorrect "onFailure-gotoStep" type', function(done) {                            
            let nStep = JSON.parse(JSON.stringify(testStep));
            nStep.onSucceed = {gotoStep: 2};
            nStep.onFailure = {gotoStep: true};
            assert.equal(DataVsSchemaResult(nStep, schema.stepSchema), false);
            assert.equal(DataVsSchemaErrors(nStep, schema.stepSchema), "data.onFailure should be equal to one of the allowed values, data.onFailure.gotoStep should be integer, data.onFailure should match exactly one schema in oneOf");            
            done();
        })      
        //extra fields
        it('incorrect minimum "o"nFailure-gotoStep"', function(done) {                            
            let nStep = JSON.parse(JSON.stringify(testStep));
            nStep.onSucceed = {gotoStep: 2};
            nStep.onFailure = {gotoStep: 0};
            assert.equal(DataVsSchemaResult(nStep, schema.stepSchema), false);
            assert.equal(DataVsSchemaErrors(nStep, schema.stepSchema), "data.onFailure should be equal to one of the allowed values, data.onFailure.gotoStep should be >= 1, data.onFailure should match exactly one schema in oneOf");            
            done();
        })     
        it('incorrect "retryAttempts" type', function(done) {                            
            let nStep = JSON.parse(JSON.stringify(testStep));
            nStep.retryAttempts = 1;
            assert.equal(DataVsSchemaResult(nStep, schema.stepSchema), false);
            assert.equal(DataVsSchemaErrors(nStep, schema.stepSchema), "data.retryAttempts should be object");            
            done();
        })         
        it('extra properties "retryAttempts"', function(done) {                            
            let nStep = JSON.parse(JSON.stringify(testStep));
            nStep.retryAttempts = {number: 11, interval: 1, a: 1};
            assert.equal(DataVsSchemaResult(nStep, schema.stepSchema), false);
            assert.equal(DataVsSchemaErrors(nStep, schema.stepSchema), "data.retryAttempts should NOT have additional properties");            
            done();
        })    
        it('incorrect "retryAttempts-number" value >10', function(done) {                            
            let nStep = JSON.parse(JSON.stringify(testStep));
            nStep.retryAttempts = {number: 11, interval: 1};
            assert.equal(DataVsSchemaResult(nStep, schema.stepSchema), false);
            assert.equal(DataVsSchemaErrors(nStep, schema.stepSchema), "data.retryAttempts.number should be <= 10");            
            done();
        })  
        it('incorrect "retryAttempts-number" value <0', function(done) {                            
            let nStep = JSON.parse(JSON.stringify(testStep));
            nStep.retryAttempts = {number: -1, interval: 1};
            assert.equal(DataVsSchemaResult(nStep, schema.stepSchema), false);
            assert.equal(DataVsSchemaErrors(nStep, schema.stepSchema), "data.retryAttempts.number should be >= 0");            
            done();
        })       
        it('incorrect type "retryAttempts-number"', function(done) {                            
            let nStep = JSON.parse(JSON.stringify(testStep));
            nStep.retryAttempts = {number: true, interval: 1};
            assert.equal(DataVsSchemaResult(nStep, schema.stepSchema), false);
            assert.equal(DataVsSchemaErrors(nStep, schema.stepSchema), "data.retryAttempts.number should be integer");            
            done();
        })          
        it('incorrect "retryAttempts-interval" value <0', function(done) {                            
            let nStep = JSON.parse(JSON.stringify(testStep));
            nStep.retryAttempts = {number: 1, interval: -1};
            assert.equal(DataVsSchemaResult(nStep, schema.stepSchema), false);
            assert.equal(DataVsSchemaErrors(nStep, schema.stepSchema), "data.retryAttempts.interval should be >= 1");            
            done();
        })       
        it('incorrect type "retryAttempts-interval"', function(done) {                            
            let nStep = JSON.parse(JSON.stringify(testStep));
            nStep.retryAttempts = {number: 1, interval: true};
            assert.equal(DataVsSchemaResult(nStep, schema.stepSchema), false);
            assert.equal(DataVsSchemaErrors(nStep, schema.stepSchema), "data.retryAttempts.interval should be integer");            
            done();
        })                           
        it('requiered properties not found', function(done) {             
            schema.stepSchema['required'] = schema.stepSchemaRequired; 
            schema.stepSchema['required'].forEach(element => {
                let nStep = JSON.parse(JSON.stringify(testStep));
                delete nStep[element];    
                assert.equal(DataVsSchemaResult(nStep, schema.stepSchema), false);
                assert.equal(DataVsSchemaErrors(nStep, schema.stepSchema), "data should have required property '" + element + "'");                            
            });
            done();
        })             
    })
    describe('connection', function() {
        it('initial validation. type "mongodb". OK', function(done) {                            
            let nConnection = JSON.parse(JSON.stringify(testData.connectionOK));
            assert.equal(DataVsSchemaResult(nConnection, schema.connectionSchema), true);
            done();
        })
        it('initial validation. type "postgresql". OK', function(done) {                            
            let nConnection = JSON.parse(JSON.stringify(testData.connectionOK));
            nConnection.type = 'postgresql';
            assert.equal(DataVsSchemaResult(nConnection, schema.connectionSchema), true);
            done();
        })                
        it('incorrect "name" type', function(done) {                            
            let nConnection = JSON.parse(JSON.stringify(testData.connectionOK));
            nConnection.name = true;
            assert.equal(DataVsSchemaResult(nConnection, schema.connectionSchema), false);
            assert.equal(DataVsSchemaErrors(nConnection, schema.connectionSchema), "data.name should be string");            
            done();
        })        
        it('incorrect "host" type', function(done) {                            
            let nConnection = JSON.parse(JSON.stringify(testData.connectionOK));
            nConnection.host = true;
            assert.equal(DataVsSchemaResult(nConnection, schema.connectionSchema), false);
            assert.equal(DataVsSchemaErrors(nConnection, schema.connectionSchema), "data.host should be string");            
            done();
        })     
        it('incorrect "port" type', function(done) {                            
            let nConnection = JSON.parse(JSON.stringify(testData.connectionOK));
            nConnection.port = true;
            assert.equal(DataVsSchemaResult(nConnection, schema.connectionSchema), false);
            assert.equal(DataVsSchemaErrors(nConnection, schema.connectionSchema), "data.port should be integer");            
            done();
        })     
        it('incorrect minimal value for "port"', function(done) {                            
            let nConnection = JSON.parse(JSON.stringify(testData.connectionOK));
            nConnection.port = -1;
            assert.equal(DataVsSchemaResult(nConnection, schema.connectionSchema), false);
            assert.include(DataVsSchemaErrors(nConnection, schema.connectionSchema), "data.port should be >= 0");            
            done();
        })  
        it('incorrect maximal value for "port"', function(done) {                            
            let nConnection = JSON.parse(JSON.stringify(testData.connectionOK));
            nConnection.port = 77777;
            assert.equal(DataVsSchemaResult(nConnection, schema.connectionSchema), false);
            assert.include(DataVsSchemaErrors(nConnection, schema.connectionSchema), "data.port should be <= 65536");            
            done();
        })          
        it('incorrect "database" type', function(done) {                            
            let nConnection = JSON.parse(JSON.stringify(testData.connectionOK));
            nConnection.database = 1;
            assert.equal(DataVsSchemaResult(nConnection, schema.connectionSchema), false);
            assert.equal(DataVsSchemaErrors(nConnection, schema.connectionSchema), "data.database should be string");            
            done();
        })          
        it('incorrect "enabled" type', function(done) {                            
            let nConnection = JSON.parse(JSON.stringify(testData.connectionOK));
            nConnection.enabled = 'aaa';
            assert.equal(DataVsSchemaResult(nConnection, schema.connectionSchema), false);
            assert.equal(DataVsSchemaErrors(nConnection, schema.connectionSchema), "data.enabled should be boolean");            
            done();
        })     
        it('incorrect "login" type', function(done) {                            
            let nConnection = JSON.parse(JSON.stringify(testData.connectionOK));
            nConnection.login = 777;
            assert.equal(DataVsSchemaResult(nConnection, schema.connectionSchema), false);
            assert.equal(DataVsSchemaErrors(nConnection, schema.connectionSchema), "data.login should be string");            
            done();
        })     
        it('incorrect "password" type', function(done) {                            
            let nConnection = JSON.parse(JSON.stringify(testData.connectionOK));
            nConnection.password = true;
            assert.equal(DataVsSchemaResult(nConnection, schema.connectionSchema), false);
            assert.equal(DataVsSchemaErrors(nConnection, schema.connectionSchema), "data.password should be string");            
            done();
        })               
        it('extra property', function(done) {                            
            let nConnection = JSON.parse(JSON.stringify(testData.connectionOK));
            nConnection.fuck = true;
            assert.equal(DataVsSchemaResult(nConnection, schema.connectionSchema), false);
            assert.equal(DataVsSchemaErrors(nConnection, schema.connectionSchema), "data should NOT have additional properties");                    
            done();                        
        })                                 
        it('requiered properties not found', function(done) {             
            schema.connectionSchema['required'] = schema.connectionSchemaRequired; 
            schema.connectionSchema['required'].forEach(element => {
                let nConnection = JSON.parse(JSON.stringify(testData.connectionOK));
                delete nConnection[element];    
                assert.equal(DataVsSchemaResult(nConnection, schema.connectionSchema), false);
                assert.equal(DataVsSchemaErrors(nConnection, schema.connectionSchema), "data should have required property '" + element + "'");                            
            });
            done();
        })             
    })
});    

