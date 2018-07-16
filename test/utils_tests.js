var assert  = require('chai').assert;
var config = require('../config/config');
var utools = require('../app/tools/utools');
var validation = require('../app/tools/validation');
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
});    