var mongo = require('mongodb');
var assert  = require('chai').assert;
var request = require('request');
var Ajv = require('ajv');
var messageBox = require('../config/message_labels.js');
var schema = require('../app/models/app_models.js');
const config = require('../config/config.js');
//var fakeId = new mongo.ObjectID('0a9296f2496698264c23e180');

//job test data preparation
var testJob = {
    name: 'job',
    description: 'job description',
    enabled: true,
    steps: []  
};
//---
//step test data preparation
var testStep = {
    name: 'step',
    enabled: true,      
    connection: {},
    database: 'database',
    command: 'command',
    retryAttempts: {number: 1, interval: 5},
    onSucceed: 'quitWithFailure',
    onFailure: 'quitWithFailure'
};
//---
//schedule test data preparation
var oneTimeSchedule = {
    name: 'oneTime',
    enabled: true,
    oneTime: '2018-05-31T20:54:23.071Z'
};
var dailyScheduleOnce = {
    name: 'dailyOnce',
    enabled: true,
    eachNDay: 1,
    dailyFrequency: { occursOnceAt: '11:11:11'}
};
var dailyScheduleEvery = {
    name: 'dailyEvery',
    enabled: true,
    eachNDay: 1,
    dailyFrequency: { start: '11:11:11', occursEvery: {intervalValue: 1, intervalType: 'minute'}}
};
var weeklySchedule = {
    name: 'weekly',
    enabled: true,
    eachNWeek: 1,
    dayOfWeek: ['mon', 'wed', 'fri'],
    dailyFrequency: { occursOnceAt: '11:11:11'}
};
var monthlySchedule = {
    name: 'monthly',
    enabled: true,
    month: ['jan', 'jul'],
    day: 1,
    dailyFrequency: { start: '11:11:11', occursEvery: {intervalValue: 1, intervalType: 'minute'}}
};
//---

function DataVsSchemaResult(testData, schema, extraSchema) {
    //TODO: to be optimized with removeSchema(/.*/)
    var ajv = new Ajv();
    if(extraSchema)
        extraSchema.forEach(function(e) { ajv.addSchema(e) }); 
    let validate = ajv.compile(schema);
    return validate(testData);
}
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
        it('incorrect "enabled" type', function(done) {    
            let nJob = JSON.parse(JSON.stringify(testJob));
            nJob.enabled = 1;

            assert.equal(DataVsSchemaResult(nJob, schema.jobSchema), false);
            assert.equal(DataVsSchemaErrors(nJob, schema.jobSchema), 'data.enabled should be boolean');
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
            delete nJob.enabled;
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
            nStep.connection = 1;
            assert.equal(DataVsSchemaResult(nStep, schema.stepSchema), false);
            assert.equal(DataVsSchemaErrors(nStep, schema.stepSchema), "data.connection should be object");            
            done();
        })      
        it('incorrect "database" type', function(done) {                            
            let nStep = JSON.parse(JSON.stringify(testStep));
            nStep.database = 1;
            assert.equal(DataVsSchemaResult(nStep, schema.stepSchema), false);
            assert.equal(DataVsSchemaErrors(nStep, schema.stepSchema), "data.database should be string");            
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
    describe('schedule', function() {
        describe('oneTime', function() {
            it('initial validation. OK', function(done) {                            
                let nOneTimeSchedule = JSON.parse(JSON.stringify(oneTimeSchedule));
                assert.equal(DataVsSchemaResult(nOneTimeSchedule, schema.scheduleSchema, [schema.scheduleSchemaDaily]), true);
                done();
            })
            it('incorrect "name" type', function(done) {                                            
                let nOneTimeSchedule = JSON.parse(JSON.stringify(oneTimeSchedule));
                nOneTimeSchedule.name = 1;
                assert.equal(DataVsSchemaResult(nOneTimeSchedule, schema.scheduleSchema, [schema.scheduleSchemaDaily]), false);
                assert.include(DataVsSchemaErrors(nOneTimeSchedule, schema.scheduleSchema, [schema.scheduleSchemaDaily]), 'data.name should be string');
                done();
            })
            it('incorrect "enabled" type', function(done) {                                            
                let nOneTimeSchedule = JSON.parse(JSON.stringify(oneTimeSchedule));
                nOneTimeSchedule.enabled = 1;
                assert.equal(DataVsSchemaResult(nOneTimeSchedule, schema.scheduleSchema, [schema.scheduleSchemaDaily]), false);
                assert.include(DataVsSchemaErrors(nOneTimeSchedule, schema.scheduleSchema, [schema.scheduleSchemaDaily]), 'data.enabled should be boolean');
                done();
            })
            it('incorrect "oneTime" type', function(done) {                                            
                let nOneTimeSchedule = JSON.parse(JSON.stringify(oneTimeSchedule));
                nOneTimeSchedule.oneTime = 1;
                assert.equal(DataVsSchemaResult(nOneTimeSchedule, schema.scheduleSchema, [schema.scheduleSchemaDaily]), false);
                assert.include(DataVsSchemaErrors(nOneTimeSchedule, schema.scheduleSchema, [schema.scheduleSchemaDaily]), 'data.oneTime should be string');
                done();
            })
            it('incorrect "oneTime" format', function(done) {                                            
                let nOneTimeSchedule = JSON.parse(JSON.stringify(oneTimeSchedule));
                nOneTimeSchedule.oneTime = '18-12-1984 11:11:11';
                assert.equal(DataVsSchemaResult(nOneTimeSchedule, schema.scheduleSchema, [schema.scheduleSchemaDaily]), false);
                assert.include(DataVsSchemaErrors(nOneTimeSchedule, schema.scheduleSchema, [schema.scheduleSchemaDaily]), 'data.oneTime should match format "date-time"');
                done();
            })            
            it('extra property', function(done) {                                            
                let nOneTimeSchedule = JSON.parse(JSON.stringify(oneTimeSchedule));
                nOneTimeSchedule['bla'] = 1;
                assert.equal(DataVsSchemaResult(nOneTimeSchedule, schema.scheduleSchema, [schema.scheduleSchemaDaily]), false);
                assert.include(DataVsSchemaErrors(nOneTimeSchedule, schema.scheduleSchema, [schema.scheduleSchemaDaily]), 'data should NOT have additional properties');
                done();
            })        
            it('excluding noт mandatory field. OK', function(done) {                                            
                let nOneTimeSchedule = JSON.parse(JSON.stringify(oneTimeSchedule));
                delete nOneTimeSchedule.enabled;
                assert.equal(DataVsSchemaResult(nOneTimeSchedule, schema.scheduleSchema, [schema.scheduleSchemaDaily]), true);
                done();
            })                             
            it('requiered fileds "name" issue', function(done) {                                            
                let nOneTimeSchedule = JSON.parse(JSON.stringify(oneTimeSchedule));
                delete nOneTimeSchedule.name;
                assert.equal(DataVsSchemaResult(nOneTimeSchedule, schema.scheduleSchema, [schema.scheduleSchemaDaily]), false);
                assert.include(DataVsSchemaErrors(nOneTimeSchedule, schema.scheduleSchema, [schema.scheduleSchemaDaily]), "data should have required property 'name'");
                done();
            })                             
        });
        describe('daily', function() {
            describe('general checks', function() {
                it('initial validation dailyScheduleOnce. OK', function(done) {                            
                    let nDailyScheduleOnce = JSON.parse(JSON.stringify(dailyScheduleOnce));
                    assert.equal(DataVsSchemaResult(nDailyScheduleOnce, schema.scheduleSchema, [schema.scheduleSchemaDaily]), true);
                    done();
                })
                it('initial validation dailyScheduleEvery. OK', function(done) {                            
                    let nDailyScheduleOnce = JSON.parse(JSON.stringify(dailyScheduleEvery));
                    assert.equal(DataVsSchemaResult(nDailyScheduleOnce, schema.scheduleSchema, [schema.scheduleSchemaDaily]), true);
                    done();
                })
                it('incorrect "name" type', function(done) {                                            
                    let nDailyScheduleOnce = JSON.parse(JSON.stringify(dailyScheduleOnce));
                    nDailyScheduleOnce.name = 1;
                    assert.equal(DataVsSchemaResult(nDailyScheduleOnce, schema.scheduleSchema, [schema.scheduleSchemaDaily]), false);
                    assert.include(DataVsSchemaErrors(nDailyScheduleOnce, schema.scheduleSchema, [schema.scheduleSchemaDaily]), 'data.name should be string');
                    done();
                })
                it('incorrect "enabled" type', function(done) {                                            
                    let nDailyScheduleOnce = JSON.parse(JSON.stringify(dailyScheduleOnce));
                    nDailyScheduleOnce.enabled = 1;
                    assert.equal(DataVsSchemaResult(nDailyScheduleOnce, schema.scheduleSchema, [schema.scheduleSchemaDaily]), false);
                    assert.include(DataVsSchemaErrors(nDailyScheduleOnce, schema.scheduleSchema, [schema.scheduleSchemaDaily]), 'data.enabled should be boolean');
                    done();
                })
                it('incorrect "eachNDay" type', function(done) {                                            
                    let nDailyScheduleOnce = JSON.parse(JSON.stringify(dailyScheduleOnce));
                    nDailyScheduleOnce.eachNDay = true;
                    assert.equal(DataVsSchemaResult(nDailyScheduleOnce, schema.scheduleSchema, [schema.scheduleSchemaDaily]), false);
                    assert.include(DataVsSchemaErrors(nDailyScheduleOnce, schema.scheduleSchema, [schema.scheduleSchemaDaily]), 'data.eachNDay should be integer');
                    done();
                })
                it('incorrect "dailyFrequency" type', function(done) {                                            
                    let nDailyScheduleOnce = JSON.parse(JSON.stringify(dailyScheduleOnce));
                    nDailyScheduleOnce.dailyFrequency = 1;
                    assert.equal(DataVsSchemaResult(nDailyScheduleOnce, schema.scheduleSchema, [schema.scheduleSchemaDaily]), false);
                    assert.include(DataVsSchemaErrors(nDailyScheduleOnce, schema.scheduleSchema, [schema.scheduleSchemaDaily]), 'data.dailyFrequency should be object');
                    done();
                })                
                it('incorrect "eachNDay" =0', function(done) {                                            
                    let nDailyScheduleOnce = JSON.parse(JSON.stringify(dailyScheduleOnce));
                    nDailyScheduleOnce.eachNDay = 0;
                    assert.equal(DataVsSchemaResult(nDailyScheduleOnce, schema.scheduleSchema, [schema.scheduleSchemaDaily]), false);
                    assert.include(DataVsSchemaErrors(nDailyScheduleOnce, schema.scheduleSchema, [schema.scheduleSchemaDaily]), 'data.eachNDay should be >= 1');
                    done();
                })
                it('incorrect "eachNDay" <0', function(done) {                                            
                    let nDailyScheduleOnce = JSON.parse(JSON.stringify(dailyScheduleOnce));
                    nDailyScheduleOnce.eachNDay = -1;
                    assert.equal(DataVsSchemaResult(nDailyScheduleOnce, schema.scheduleSchema, [schema.scheduleSchemaDaily]), false);
                    assert.include(DataVsSchemaErrors(nDailyScheduleOnce, schema.scheduleSchema, [schema.scheduleSchemaDaily]), 'data.eachNDay should be >= 1');
                    done();
                })                                         
                it('extra property', function(done) {                                            
                    let nDailyScheduleOnce = JSON.parse(JSON.stringify(dailyScheduleOnce));
                    nDailyScheduleOnce['bla'] = 1;
                    assert.equal(DataVsSchemaResult(nDailyScheduleOnce, schema.scheduleSchema, [schema.scheduleSchemaDaily]), false);
                    assert.include(DataVsSchemaErrors(nDailyScheduleOnce, schema.scheduleSchema, [schema.scheduleSchemaDaily]), 'data should NOT have additional properties');
                    done();
                })        
                it('excluding noт mandatory field. OK', function(done) {                                            
                    let nDailyScheduleOnce = JSON.parse(JSON.stringify(dailyScheduleOnce));
                    delete nDailyScheduleOnce.enabled;
                    assert.equal(DataVsSchemaResult(nDailyScheduleOnce, schema.scheduleSchema, [schema.scheduleSchemaDaily]), true);
                    done();
                })                             
                it('requiered fileds "name" issue', function(done) {                                            
                    let nDailyScheduleOnce = JSON.parse(JSON.stringify(dailyScheduleOnce));
                    delete nDailyScheduleOnce.name;
                    assert.equal(DataVsSchemaResult(nDailyScheduleOnce, schema.scheduleSchema, [schema.scheduleSchemaDaily]), false);
                    assert.include(DataVsSchemaErrors(nDailyScheduleOnce, schema.scheduleSchema, [schema.scheduleSchemaDaily]), "data should have required property 'name'");
                    done();
                })    
                it('requiered fileds "eachNDay" issue', function(done) {                                            
                    let nDailyScheduleOnce = JSON.parse(JSON.stringify(dailyScheduleOnce));
                    delete nDailyScheduleOnce.eachNDay;
                    assert.equal(DataVsSchemaResult(nDailyScheduleOnce, schema.scheduleSchema, [schema.scheduleSchemaDaily]), false);
                    assert.include(DataVsSchemaErrors(nDailyScheduleOnce, schema.scheduleSchema, [schema.scheduleSchemaDaily]), "data should have required property 'eachNDay'");
                    done();
                })           
                describe('once', function() {
                    it('incorrect "dailyFrequency.occursOnceAt" type', function(done) {                                            
                        let nDailyScheduleOnce = JSON.parse(JSON.stringify(dailyScheduleOnce));
                        nDailyScheduleOnce.dailyFrequency.occursOnceAt = 1;
                        assert.equal(DataVsSchemaResult(nDailyScheduleOnce, schema.scheduleSchema, [schema.scheduleSchemaDaily]), false);
                        assert.include(DataVsSchemaErrors(nDailyScheduleOnce, schema.scheduleSchema, [schema.scheduleSchemaDaily]), 'data.dailyFrequency.occursOnceAt should be string');
                        done();
                    })
                    it('incorrect "dailyFrequency.occursOnceAt" format (11)', function(done) {                                            
                        let nDailyScheduleOnce = JSON.parse(JSON.stringify(dailyScheduleOnce));
                        nDailyScheduleOnce.dailyFrequency.occursOnceAt = '11';
                        assert.equal(DataVsSchemaResult(nDailyScheduleOnce, schema.scheduleSchema, [schema.scheduleSchemaDaily]), false);
                        assert.include(DataVsSchemaErrors(nDailyScheduleOnce, schema.scheduleSchema, [schema.scheduleSchemaDaily]), 'data.dailyFrequency.occursOnceAt should match format "time"');
                        done();
                    })
                    it('incorrect "dailyFrequency.occursOnceAt" format (11:11:99)', function(done) {                                            
                        let nDailyScheduleOnce = JSON.parse(JSON.stringify(dailyScheduleOnce));
                        nDailyScheduleOnce.dailyFrequency.occursOnceAt = '11:11:99';
                        assert.equal(DataVsSchemaResult(nDailyScheduleOnce, schema.scheduleSchema, [schema.scheduleSchemaDaily]), false);
                        assert.include(DataVsSchemaErrors(nDailyScheduleOnce, schema.scheduleSchema, [schema.scheduleSchemaDaily]), 'data.dailyFrequency.occursOnceAt should match format "time"');
                        done();
                    })        
                    it('extra property', function(done) {                                            
                        let nDailyScheduleOnce = JSON.parse(JSON.stringify(dailyScheduleOnce));
                        nDailyScheduleOnce.dailyFrequency['bla'] = 1;
                        assert.equal(DataVsSchemaResult(nDailyScheduleOnce, schema.scheduleSchema, [schema.scheduleSchemaDaily]), false);
                        assert.include(DataVsSchemaErrors(nDailyScheduleOnce, schema.scheduleSchema, [schema.scheduleSchemaDaily]), 'data.dailyFrequency should NOT have additional properties');
                        done();
                    })                    
                    it('requiered fileds "occursOnceAt" issue', function(done) {                                            
                        let nDailyScheduleOnce = JSON.parse(JSON.stringify(dailyScheduleOnce));
                        delete nDailyScheduleOnce.dailyFrequency.occursOnceAt;
                        assert.equal(DataVsSchemaResult(nDailyScheduleOnce, schema.scheduleSchema, [schema.scheduleSchemaDaily]), false);
                        assert.include(DataVsSchemaErrors(nDailyScheduleOnce, schema.scheduleSchema, [schema.scheduleSchemaDaily]), "data.dailyFrequency should have required property 'occursOnceAt'");
                        done();
                    })                                  
                })
                describe('every', function() {
                    it('incorrect "dailyFrequency.start" type', function(done) {                                            
                        let nDailyScheduleEvery = JSON.parse(JSON.stringify(dailyScheduleEvery));
                        nDailyScheduleEvery.dailyFrequency.start = 1;
                        assert.equal(DataVsSchemaResult(nDailyScheduleEvery, schema.scheduleSchema, [schema.scheduleSchemaDaily]), false);
                        assert.include(DataVsSchemaErrors(nDailyScheduleEvery, schema.scheduleSchema, [schema.scheduleSchemaDaily]), 'data.dailyFrequency.start should be string');
                        done();
                    })          
                    it('incorrect "dailyFrequency.start" format (11)', function(done) {                                            
                        let nDailyScheduleEvery = JSON.parse(JSON.stringify(dailyScheduleEvery));
                        nDailyScheduleEvery.dailyFrequency.start = '11';
                        assert.equal(DataVsSchemaResult(nDailyScheduleEvery, schema.scheduleSchema, [schema.scheduleSchemaDaily]), false);
                        assert.include(DataVsSchemaErrors(nDailyScheduleEvery, schema.scheduleSchema, [schema.scheduleSchemaDaily]), 'data.dailyFrequency.start should match format "time"');
                        done();
                    })
                    it('incorrect "dailyFrequency.start" format (11:11:99)', function(done) {                                            
                        let nDailyScheduleEvery = JSON.parse(JSON.stringify(dailyScheduleEvery));
                        nDailyScheduleEvery.dailyFrequency.start = '11:11:99';
                        assert.equal(DataVsSchemaResult(nDailyScheduleEvery, schema.scheduleSchema, [schema.scheduleSchemaDaily]), false);
                        assert.include(DataVsSchemaErrors(nDailyScheduleEvery, schema.scheduleSchema, [schema.scheduleSchemaDaily]), 'data.dailyFrequency.start should match format "time"');
                        done();
                    })    
                    it('incorrect "dailyFrequency.occursEvery" type', function(done) {                                            
                        let nDailyScheduleEvery = JSON.parse(JSON.stringify(dailyScheduleEvery));
                        nDailyScheduleEvery.dailyFrequency.occursEvery = 1;
                        assert.equal(DataVsSchemaResult(nDailyScheduleEvery, schema.scheduleSchema, [schema.scheduleSchemaDaily]), false);
                        assert.include(DataVsSchemaErrors(nDailyScheduleEvery, schema.scheduleSchema, [schema.scheduleSchemaDaily]), 'data.dailyFrequency.occursEvery should be object');
                        done();
                    })  
                    it('extra property', function(done) {                                            
                        let nDailyScheduleEvery = JSON.parse(JSON.stringify(dailyScheduleOnce));
                        nDailyScheduleEvery.dailyFrequency['bla'] = 1;
                        assert.equal(DataVsSchemaResult(nDailyScheduleEvery, schema.scheduleSchema, [schema.scheduleSchemaDaily]), false);
                        assert.include(DataVsSchemaErrors(nDailyScheduleEvery, schema.scheduleSchema, [schema.scheduleSchemaDaily]), 'data.dailyFrequency should NOT have additional properties');
                        done();
                    })                    
                    it('requiered fileds "dailyFrequency.start" issue', function(done) {                                            
                        let nDailyScheduleEvery = JSON.parse(JSON.stringify(dailyScheduleEvery));
                        delete nDailyScheduleEvery.dailyFrequency.start;
                        assert.equal(DataVsSchemaResult(nDailyScheduleEvery, schema.scheduleSchema, [schema.scheduleSchemaDaily]), false);
                        assert.include(DataVsSchemaErrors(nDailyScheduleEvery, schema.scheduleSchema, [schema.scheduleSchemaDaily]), "data.dailyFrequency should have required property 'start'");
                        done();
                    })              
                    it('requiered fileds "dailyFrequency.occursEvery" issue', function(done) {                                            
                        let nDailyScheduleEvery = JSON.parse(JSON.stringify(dailyScheduleEvery));
                        delete nDailyScheduleEvery.dailyFrequency.occursEvery;
                        assert.equal(DataVsSchemaResult(nDailyScheduleEvery, schema.scheduleSchema, [schema.scheduleSchemaDaily]), false);
                        assert.include(DataVsSchemaErrors(nDailyScheduleEvery, schema.scheduleSchema, [schema.scheduleSchemaDaily]), "data.dailyFrequency should have required property 'occursEvery'");
                        done();
                    })          
                    describe('occursEvery', function() {
                        it('incorrect "dailyFrequency.occursEvery.intervalValue" type', function(done) {                                            
                            let nDailyScheduleEvery = JSON.parse(JSON.stringify(dailyScheduleEvery));
                            nDailyScheduleEvery.dailyFrequency.occursEvery.intervalValue = true;
                            assert.equal(DataVsSchemaResult(nDailyScheduleEvery, schema.scheduleSchema, [schema.scheduleSchemaDaily]), false);
                            assert.include(DataVsSchemaErrors(nDailyScheduleEvery, schema.scheduleSchema, [schema.scheduleSchemaDaily]), 'data.dailyFrequency.occursEvery.intervalValue should be integer');
                            done();
                        })   
                        it('incorrect "dailyFrequency.occursEvery.intervalValue" <0', function(done) {                                            
                            let nDailyScheduleEvery = JSON.parse(JSON.stringify(dailyScheduleEvery));
                            nDailyScheduleEvery.dailyFrequency.occursEvery.intervalValue = -1;
                            assert.equal(DataVsSchemaResult(nDailyScheduleEvery, schema.scheduleSchema, [schema.scheduleSchemaDaily]), false);
                            assert.include(DataVsSchemaErrors(nDailyScheduleEvery, schema.scheduleSchema, [schema.scheduleSchemaDaily]), 'data.dailyFrequency.occursEvery.intervalValue should be >= 0');
                            done();
                        }) 
                        it('incorrect "dailyFrequency.occursEvery.intervalType" type', function(done) {                                            
                            let nDailyScheduleEvery = JSON.parse(JSON.stringify(dailyScheduleEvery));
                            nDailyScheduleEvery.dailyFrequency.occursEvery.intervalType = true;
                            assert.equal(DataVsSchemaResult(nDailyScheduleEvery, schema.scheduleSchema, [schema.scheduleSchemaDaily]), false);
                            assert.include(DataVsSchemaErrors(nDailyScheduleEvery, schema.scheduleSchema, [schema.scheduleSchemaDaily]), 'data.dailyFrequency.occursEvery.intervalType should be equal to one of the allowed values');
                            done();
                        })  
                        it('incorrect "dailyFrequency.occursEvery.intervalType" value', function(done) {                                            
                            let nDailyScheduleEvery = JSON.parse(JSON.stringify(dailyScheduleEvery));
                            nDailyScheduleEvery.dailyFrequency.occursEvery.intervalType = 'a';
                            assert.equal(DataVsSchemaResult(nDailyScheduleEvery, schema.scheduleSchema, [schema.scheduleSchemaDaily]), false);
                            assert.include(DataVsSchemaErrors(nDailyScheduleEvery, schema.scheduleSchema, [schema.scheduleSchemaDaily]), 'data.dailyFrequency.occursEvery.intervalType should be equal to one of the allowed values');
                            done();
                        })      
                        it('extra property', function(done) {                                            
                            let nDailyScheduleEvery = JSON.parse(JSON.stringify(dailyScheduleEvery));
                            nDailyScheduleEvery.dailyFrequency.occursEvery['bla'] = 1;
                            assert.equal(DataVsSchemaResult(nDailyScheduleEvery, schema.scheduleSchema, [schema.scheduleSchemaDaily]), false);
                            assert.include(DataVsSchemaErrors(nDailyScheduleEvery, schema.scheduleSchema, [schema.scheduleSchemaDaily]), 'data.dailyFrequency.occursEvery should NOT have additional properties');
                            done();
                        })       
                        it('requiered fileds "dailyFrequency.occursEvery.intervalValue" issue', function(done) {                                            
                            let nDailyScheduleEvery = JSON.parse(JSON.stringify(dailyScheduleEvery));
                            delete nDailyScheduleEvery.dailyFrequency.occursEvery.intervalValue;
                            assert.equal(DataVsSchemaResult(nDailyScheduleEvery, schema.scheduleSchema, [schema.scheduleSchemaDaily]), false);
                            assert.include(DataVsSchemaErrors(nDailyScheduleEvery, schema.scheduleSchema, [schema.scheduleSchemaDaily]), "data.dailyFrequency.occursEvery should have required property 'intervalValue'");
                            done();
                        })   
                        it('requiered fileds "dailyFrequency.occursEvery.intervalType" issue', function(done) {                                            
                            let nDailyScheduleEvery = JSON.parse(JSON.stringify(dailyScheduleEvery));
                            delete nDailyScheduleEvery.dailyFrequency.occursEvery.intervalType;
                            assert.equal(DataVsSchemaResult(nDailyScheduleEvery, schema.scheduleSchema, [schema.scheduleSchemaDaily]), false);
                            assert.include(DataVsSchemaErrors(nDailyScheduleEvery, schema.scheduleSchema, [schema.scheduleSchemaDaily]), "data.dailyFrequency.occursEvery should have required property 'intervalType'");
                            done();
                        })                                           
                    })                     
                })                                      
            });
        });
        describe('weekly', function() {
            it('initial validation. OK', function(done) {                            
                let nWeeklySchedule = JSON.parse(JSON.stringify(weeklySchedule));
                assert.equal(DataVsSchemaResult(nWeeklySchedule, schema.scheduleSchema, [schema.scheduleSchemaDaily]), true);
                done();
            })
            it('incorrect "name" type', function(done) {                                            
                let nWeeklySchedule = JSON.parse(JSON.stringify(weeklySchedule));
                nWeeklySchedule.name = 1;
                assert.equal(DataVsSchemaResult(nWeeklySchedule, schema.scheduleSchema, [schema.scheduleSchemaDaily]), false);
                assert.include(DataVsSchemaErrors(nWeeklySchedule, schema.scheduleSchema, [schema.scheduleSchemaDaily]), 'data.name should be string');
                done();
            })
            it('incorrect "enabled" type', function(done) {                                            
                let nWeeklySchedule = JSON.parse(JSON.stringify(weeklySchedule));
                nWeeklySchedule.enabled = 1;
                assert.equal(DataVsSchemaResult(nWeeklySchedule, schema.scheduleSchema, [schema.scheduleSchemaDaily]), false);
                assert.include(DataVsSchemaErrors(nWeeklySchedule, schema.scheduleSchema, [schema.scheduleSchemaDaily]), 'data.enabled should be boolean');
                done();
            })
            it('incorrect "eachNWeek" type', function(done) {                                            
                let nWeeklySchedule = JSON.parse(JSON.stringify(weeklySchedule));
                nWeeklySchedule.eachNWeek = true;
                assert.equal(DataVsSchemaResult(nWeeklySchedule, schema.scheduleSchema, [schema.scheduleSchemaDaily]), false);
                assert.include(DataVsSchemaErrors(nWeeklySchedule, schema.scheduleSchema, [schema.scheduleSchemaDaily]), 'data.eachNWeek should be integer');
                done();
            })
            it('incorrect "dailyFrequency" type', function(done) {                                            
                let nWeeklySchedule = JSON.parse(JSON.stringify(weeklySchedule));
                nWeeklySchedule.dailyFrequency = 1;
                assert.equal(DataVsSchemaResult(nWeeklySchedule, schema.scheduleSchema, [schema.scheduleSchemaDaily]), false);
                assert.include(DataVsSchemaErrors(nWeeklySchedule, schema.scheduleSchema, [schema.scheduleSchemaDaily]), 'data.dailyFrequency should be object');
                done();
            })                
            it('incorrect "eachNWeek" =0', function(done) {                                            
                let nWeeklySchedule = JSON.parse(JSON.stringify(weeklySchedule));
                nWeeklySchedule.eachNWeek = 0;
                assert.equal(DataVsSchemaResult(nWeeklySchedule, schema.scheduleSchema, [schema.scheduleSchemaDaily]), false);
                assert.include(DataVsSchemaErrors(nWeeklySchedule, schema.scheduleSchema, [schema.scheduleSchemaDaily]), 'data.eachNWeek should be >= 1');
                done();
            })
            it('incorrect "eachNWeek" <0', function(done) {                                            
                let nWeeklySchedule = JSON.parse(JSON.stringify(weeklySchedule));
                nWeeklySchedule.eachNWeek = -1;
                assert.equal(DataVsSchemaResult(nWeeklySchedule, schema.scheduleSchema, [schema.scheduleSchemaDaily]), false);
                assert.include(DataVsSchemaErrors(nWeeklySchedule, schema.scheduleSchema, [schema.scheduleSchemaDaily]), 'data.eachNWeek should be >= 1');
                done();
            })       
            it('incorrect "dayOfWeek" type', function(done) {                                            
                let nWeeklySchedule = JSON.parse(JSON.stringify(weeklySchedule));
                nWeeklySchedule.dayOfWeek = true;
                assert.equal(DataVsSchemaResult(nWeeklySchedule, schema.scheduleSchema, [schema.scheduleSchemaDaily]), false);
                assert.include(DataVsSchemaErrors(nWeeklySchedule, schema.scheduleSchema, [schema.scheduleSchemaDaily]), 'data.dayOfWeek should be array');
                done();
            })               
            it('incorrect "dayOfWeek" value', function(done) {                                            
                let nWeeklySchedule = JSON.parse(JSON.stringify(weeklySchedule));
                nWeeklySchedule.dayOfWeek = ['zzz'];
                assert.equal(DataVsSchemaResult(nWeeklySchedule, schema.scheduleSchema, [schema.scheduleSchemaDaily]), false);
                assert.include(DataVsSchemaErrors(nWeeklySchedule, schema.scheduleSchema, [schema.scheduleSchemaDaily]), 'data.dayOfWeek[0] should be equal to one of the allowed values');
                done();
            })             
            it('"dayOfWeek" contains not unique items', function(done) {                                            
                let nWeeklySchedule = JSON.parse(JSON.stringify(weeklySchedule));
                nWeeklySchedule.dayOfWeek = ['mon', 'fri', 'mon'];
                assert.equal(DataVsSchemaResult(nWeeklySchedule, schema.scheduleSchema, [schema.scheduleSchemaDaily]), false);
                assert.include(DataVsSchemaErrors(nWeeklySchedule, schema.scheduleSchema, [schema.scheduleSchemaDaily]), 'data.dayOfWeek should NOT have duplicate items');
                done();
            })                                   
            it('extra property', function(done) {                                            
                let nWeeklySchedule = JSON.parse(JSON.stringify(weeklySchedule));
                nWeeklySchedule['bla'] = 1;
                assert.equal(DataVsSchemaResult(nWeeklySchedule, schema.scheduleSchema, [schema.scheduleSchemaDaily]), false);
                assert.include(DataVsSchemaErrors(nWeeklySchedule, schema.scheduleSchema, [schema.scheduleSchemaDaily]), 'data should NOT have additional properties');
                done();
            })        
            it('excluding noт mandatory field. OK', function(done) {                                            
                let nWeeklySchedule = JSON.parse(JSON.stringify(weeklySchedule));
                delete nWeeklySchedule.enabled;
                assert.equal(DataVsSchemaResult(nWeeklySchedule, schema.scheduleSchema, [schema.scheduleSchemaDaily]), true);
                done();
            })                             
            it('requiered fileds "name" issue', function(done) {                                            
                let nWeeklySchedule = JSON.parse(JSON.stringify(weeklySchedule));
                delete nWeeklySchedule.name;
                assert.equal(DataVsSchemaResult(nWeeklySchedule, schema.scheduleSchema, [schema.scheduleSchemaDaily]), false);
                assert.include(DataVsSchemaErrors(nWeeklySchedule, schema.scheduleSchema, [schema.scheduleSchemaDaily]), "data should have required property 'name'");
                done();
            })    
            it('requiered fileds "eachNWeek" issue', function(done) {                                            
                let nWeeklySchedule = JSON.parse(JSON.stringify(weeklySchedule));
                delete nWeeklySchedule.eachNWeek;
                assert.equal(DataVsSchemaResult(nWeeklySchedule, schema.scheduleSchema, [schema.scheduleSchemaDaily]), false);
                assert.include(DataVsSchemaErrors(nWeeklySchedule, schema.scheduleSchema, [schema.scheduleSchemaDaily]), "data should have required property 'eachNWeek'");
                done();
            })
            it('requiered fileds "dayOfWeek" issue', function(done) {                                            
                let nWeeklySchedule = JSON.parse(JSON.stringify(weeklySchedule));
                delete nWeeklySchedule.dayOfWeek;
                assert.equal(DataVsSchemaResult(nWeeklySchedule, schema.scheduleSchema, [schema.scheduleSchemaDaily]), false);
                assert.include(DataVsSchemaErrors(nWeeklySchedule, schema.scheduleSchema, [schema.scheduleSchemaDaily]), "data should have required property 'dayOfWeek'");
                done();
            })            
        });    
        describe('monthly', function() {
            it('initial validation. OK', function(done) {                            
                let nMonthlySchedule = JSON.parse(JSON.stringify(monthlySchedule));
                assert.equal(DataVsSchemaResult(nMonthlySchedule, schema.scheduleSchema, [schema.scheduleSchemaDaily]), true);
                done();
            })
            it('incorrect "name" type', function(done) {                                            
                let nMonthlySchedule = JSON.parse(JSON.stringify(monthlySchedule));
                nMonthlySchedule.name = 1;
                assert.equal(DataVsSchemaResult(nMonthlySchedule, schema.scheduleSchema, [schema.scheduleSchemaDaily]), false);
                assert.include(DataVsSchemaErrors(nMonthlySchedule, schema.scheduleSchema, [schema.scheduleSchemaDaily]), 'data.name should be string');
                done();
            })
            it('incorrect "enabled" type', function(done) {                                            
                let nMonthlySchedule = JSON.parse(JSON.stringify(monthlySchedule));
                nMonthlySchedule.enabled = 1;
                assert.equal(DataVsSchemaResult(nMonthlySchedule, schema.scheduleSchema, [schema.scheduleSchemaDaily]), false);
                assert.include(DataVsSchemaErrors(nMonthlySchedule, schema.scheduleSchema, [schema.scheduleSchemaDaily]), 'data.enabled should be boolean');
                done();
            })
            it('incorrect "month" type', function(done) {                                            
                let nMonthlySchedule = JSON.parse(JSON.stringify(monthlySchedule));
                nMonthlySchedule.month = true;
                assert.equal(DataVsSchemaResult(nMonthlySchedule, schema.scheduleSchema, [schema.scheduleSchemaDaily]), false);
                assert.include(DataVsSchemaErrors(nMonthlySchedule, schema.scheduleSchema, [schema.scheduleSchemaDaily]), 'data.month should be array');
                done();
            })
            it('incorrect "day" type', function(done) {                                            
                let nMonthlySchedule = JSON.parse(JSON.stringify(monthlySchedule));
                nMonthlySchedule.day = true;
                assert.equal(DataVsSchemaResult(nMonthlySchedule, schema.scheduleSchema, [schema.scheduleSchemaDaily]), false);
                assert.include(DataVsSchemaErrors(nMonthlySchedule, schema.scheduleSchema, [schema.scheduleSchemaDaily]), 'data.day should be integer');
                done();
            })            
            it('incorrect "dailyFrequency" type', function(done) {                                            
                let nMonthlySchedule = JSON.parse(JSON.stringify(monthlySchedule));
                nMonthlySchedule.dailyFrequency = 1;
                assert.equal(DataVsSchemaResult(nMonthlySchedule, schema.scheduleSchema, [schema.scheduleSchemaDaily]), false);
                assert.include(DataVsSchemaErrors(nMonthlySchedule, schema.scheduleSchema, [schema.scheduleSchemaDaily]), 'data.dailyFrequency should be object');
                done();
            })                
            it('incorrect "day" =0', function(done) {                                            
                let nMonthlySchedule = JSON.parse(JSON.stringify(monthlySchedule));
                nMonthlySchedule.day = 0;
                assert.equal(DataVsSchemaResult(nMonthlySchedule, schema.scheduleSchema, [schema.scheduleSchemaDaily]), false);
                assert.include(DataVsSchemaErrors(nMonthlySchedule, schema.scheduleSchema, [schema.scheduleSchemaDaily]), 'data.day should be >= 1');
                done();
            })
            it('incorrect "day" <0', function(done) {                                            
                let nMonthlySchedule = JSON.parse(JSON.stringify(monthlySchedule));
                nMonthlySchedule.day = -1;
                assert.equal(DataVsSchemaResult(nMonthlySchedule, schema.scheduleSchema, [schema.scheduleSchemaDaily]), false);
                assert.include(DataVsSchemaErrors(nMonthlySchedule, schema.scheduleSchema, [schema.scheduleSchemaDaily]), 'data.day should be >= 1');
                done();
            })       
            it('incorrect "day" >31', function(done) {                                            
                let nMonthlySchedule = JSON.parse(JSON.stringify(monthlySchedule));
                nMonthlySchedule.day = 32;
                assert.equal(DataVsSchemaResult(nMonthlySchedule, schema.scheduleSchema, [schema.scheduleSchemaDaily]), false);
                assert.include(DataVsSchemaErrors(nMonthlySchedule, schema.scheduleSchema, [schema.scheduleSchemaDaily]), 'data.day should be <= 31');
                done();
            })                     
            it('incorrect "month" value', function(done) {                                            
                let nMonthlySchedule = JSON.parse(JSON.stringify(monthlySchedule));
                nMonthlySchedule.month = ['zzz'];
                assert.equal(DataVsSchemaResult(nMonthlySchedule, schema.scheduleSchema, [schema.scheduleSchemaDaily]), false);
                assert.include(DataVsSchemaErrors(nMonthlySchedule, schema.scheduleSchema, [schema.scheduleSchemaDaily]), 'data.month[0] should be equal to one of the allowed values');
                done();
            })             
            it('"month" contains not unique items', function(done) {                                            
                let nMonthlySchedule = JSON.parse(JSON.stringify(monthlySchedule));
                nMonthlySchedule.month = ['jan', 'dec', 'jan'];
                assert.equal(DataVsSchemaResult(nMonthlySchedule, schema.scheduleSchema, [schema.scheduleSchemaDaily]), false);
                assert.include(DataVsSchemaErrors(nMonthlySchedule, schema.scheduleSchema, [schema.scheduleSchemaDaily]), 'data.month should NOT have duplicate items');
                done();
            })                                   
            it('extra property', function(done) {                                            
                let nMonthlySchedule = JSON.parse(JSON.stringify(monthlySchedule));
                nMonthlySchedule['bla'] = 1;
                assert.equal(DataVsSchemaResult(nMonthlySchedule, schema.scheduleSchema, [schema.scheduleSchemaDaily]), false);
                assert.include(DataVsSchemaErrors(nMonthlySchedule, schema.scheduleSchema, [schema.scheduleSchemaDaily]), 'data should NOT have additional properties');
                done();
            })        
            it('excluding noт mandatory field. OK', function(done) {                                            
                let nMonthlySchedule = JSON.parse(JSON.stringify(monthlySchedule));
                delete nMonthlySchedule.enabled;
                assert.equal(DataVsSchemaResult(nMonthlySchedule, schema.scheduleSchema, [schema.scheduleSchemaDaily]), true);
                done();
            })                             
            it('requiered fileds "name" issue', function(done) {                                            
                let nMonthlySchedule = JSON.parse(JSON.stringify(monthlySchedule));
                delete nMonthlySchedule.name;
                assert.equal(DataVsSchemaResult(nMonthlySchedule, schema.scheduleSchema, [schema.scheduleSchemaDaily]), false);
                assert.include(DataVsSchemaErrors(nMonthlySchedule, schema.scheduleSchema, [schema.scheduleSchemaDaily]), "data should have required property 'name'");
                done();
            })    
            it('requiered fileds "month" issue', function(done) {                                            
                let nMonthlySchedule = JSON.parse(JSON.stringify(monthlySchedule));
                delete nMonthlySchedule.month;
                assert.equal(DataVsSchemaResult(nMonthlySchedule, schema.scheduleSchema, [schema.scheduleSchemaDaily]), false);
                assert.include(DataVsSchemaErrors(nMonthlySchedule, schema.scheduleSchema, [schema.scheduleSchemaDaily]), "data should have required property 'month'");
                done();
            })
            it('requiered fileds "day" issue', function(done) {                                            
                let nMonthlySchedule = JSON.parse(JSON.stringify(monthlySchedule));
                delete nMonthlySchedule.day;
                assert.equal(DataVsSchemaResult(nMonthlySchedule, schema.scheduleSchema, [schema.scheduleSchemaDaily]), false);
                assert.include(DataVsSchemaErrors(nMonthlySchedule, schema.scheduleSchema, [schema.scheduleSchemaDaily]), "data should have required property 'day'");
                done();
            })        
        });               
    })
});    

