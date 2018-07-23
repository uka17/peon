// utools/validation.js
var assert  = require('chai').assert;
var config = require('../config/config');
var utools = require('../app/tools/utools');
var validation = require('../app/tools/validations');
var models = require('../app/models/app_models');
var testData = require('./test_data');

describe('validation', function() {
    describe('timeIsValid', function() {
        it('OK (' + testData.validTime + ')', function(done) {        
            assert.equal(validation.timeIsValid(testData.validTime), true);        
            done();
        });  
        
        testData.invalidTimes.forEach(element => {            
            it('NOK (' + element.toString() + ')', function(done) {      
                assert.equal(validation.timeIsValid(element), false);            
                done();
            });   
        });        
    });

    describe('dateTimeIsValid', function() {
        it('OK (' + testData.validDateTime + ')', function(done) {        
            assert.equal(validation.dateTimeIsValid(testData.validDateTime), true);        
            done();
        });  
        
        testData.invalidDateTimes.forEach(element => {            
            it('NOK (' + element.toString() + ')', function(done) {      
                assert.equal(validation.dateTimeIsValid(element), false);            
                done();
            });   
        });        
    });    

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
});    