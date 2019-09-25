/* eslint-disable no-undef */
//validation unit tests
var assert  = require('chai').assert;
var validation = require('../../app/tools/validation');
var testData = require('../test_data');

describe('validation', function() {
  describe('1 validateConnection', function() {
    it('1.1 OK (' + testData.connectionOK.name + ')', function(done) {        
      assert.equal(validation.validateConnection(testData.connectionOK).isValid, true);        
      done();
    });  
        
    testData.connectionNOK.forEach((element, index ) => {            
      it('1.2.' + index.toString() +' NOK (' + element.name + ')', function(done) {      
        assert.equal(validation.validateConnection(element).isValid, false);            
        done();
      });   
    });        
  });     
    
  describe('3 validateJob', function() {
    it('3.1 OK (' + testData.jobOK.name + ')', function(done) {        
      assert.equal(validation.validateJob(testData.jobOK).isValid, true);        
      done();
    });  
  });  

  describe('4 validateStepList', function() {
    it('4.1 OK (' + testData.jobOK.name + '.steps)', function(done) {   
      let nJob = JSON.parse(JSON.stringify(testData.jobOK));
      assert.equal(validation.validateStepList(nJob.steps).isValid, true);        
      done();
    }); 

    it('4.2 NOK (' + testData.jobOK.name + '.steps)', function(done) {   
      let nJob = JSON.parse(JSON.stringify(testData.jobOK));
      nJob.steps[0].name = true;
      assert.equal(validation.validateStepList(nJob.steps).isValid, false);        
      done();
    });  
  });     
});    