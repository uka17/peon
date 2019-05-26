//validation unit tests
var assert  = require('chai').assert;
var config = require('../config/config');
var util = require('../app/tools/util');
var validation = require('../app/tools/validation');
var models = require('../app/models/app_models.json');
var testData = require('./test_data');

describe('validation', function() {
    describe('validateConnection', function() {
        it('OK (' + testData.connectionOK.name + ')', function(done) {        
            assert.equal(validation.validateConnection(testData.connectionOK).isValid, true);        
            done();
        });  
        
        testData.connectionNOK.forEach(element => {            
            it('NOK (' + element.name + ')', function(done) {      
                assert.equal(validation.validateConnection(element).isValid, false);            
                done();
            });   
        });        
    });     
    
    describe('validateJob', function() {
        it('OK (' + testData.jobOK.name + ')', function(done) {        
            assert.equal(validation.validateJob(testData.jobOK).isValid, true);        
            done();
        });  
    });  

    describe('validateStepList', function() {
        it('OK (' + testData.jobOK.name + '.steps)', function(done) {   
            let nJob = JSON.parse(JSON.stringify(testData.jobOK));
            assert.equal(validation.validateStepList(nJob.steps).isValid, true);        
            done();
        }); 

        it('NOK (' + testData.jobOK.name + '.steps)', function(done) {   
            let nJob = JSON.parse(JSON.stringify(testData.jobOK));
            nJob.steps[0].name = true;
            assert.equal(validation.validateStepList(nJob.steps).isValid, false);        
            done();
        });  
    });     
});    