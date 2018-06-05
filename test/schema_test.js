var mongo = require('mongodb');
var assert  = require('chai').assert;
var request = require('request');
var Ajv = require('ajv');
var ajv = new Ajv();
var messageBox = require('../config/message_labels.js');
var schema = require('../app/models/app_models.js');
const config = require('../config/config.js');
var fakeId = new mongo.ObjectID('0a9296f2496698264c23e180');

//test data preparation
var testJob = {
    name: 'job',
    description: 'job description',
    enabled: true,
    steps: []  
};
//---

function DataVsSchemaResult(testData, schema) {
    let validate = ajv.compile(schema);
    return validate(testData);
}
function DataVsSchemaErrors(testData, schema) {
    let validate = ajv.compile(schema);
    validate(testData);
    return ajv.errorsText(validate.errors);
}

describe('Schema validation', function() {
    describe('job', function() {
        it('initial validation. OK', function(done) {                            
            assert.equal(DataVsSchemaResult(testJob, schema.jobSchema), true);
            done();
        })
        it('incorrect name type', function(done) {    
            let nJob = JSON.parse(JSON.stringify(testJob));
            nJob.name = 1;

            assert.equal(DataVsSchemaResult(nJob, schema.jobSchema), false);
            assert.equal(DataVsSchemaErrors(nJob, schema.jobSchema), 'data.name should be string');
            done();
        })        
        it('incorrect description type', function(done) {    
            let nJob = JSON.parse(JSON.stringify(testJob));
            nJob.description = 1;

            assert.equal(DataVsSchemaResult(nJob, schema.jobSchema), false);
            assert.equal(DataVsSchemaErrors(nJob, schema.jobSchema), 'data.description should be string');
            done();
        })     
        it('incorrect enabled type', function(done) {    
            let nJob = JSON.parse(JSON.stringify(testJob));
            nJob.enabled = 1;

            assert.equal(DataVsSchemaResult(nJob, schema.jobSchema), false);
            assert.equal(DataVsSchemaErrors(nJob, schema.jobSchema), 'data.enabled should be boolean');
            done();
        })      
        it('incorrect steps type', function(done) {    
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
            delete nJob.enabled;
            schema.jobSchema['required'] = schema.jobSchemaRequired; 

            assert.equal(DataVsSchemaResult(nJob, schema.jobSchema), false);
            assert.equal(DataVsSchemaErrors(nJob, schema.jobSchema), "data should have required property 'enabled'");
            done();
        })                         
    })
});    