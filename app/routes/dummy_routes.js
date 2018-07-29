// routes/dummy_routes.js
var utools = require('../tools/utools');
const config = require('../../config/config');
var validation = require('../tools/validations');
var ver = '/v1.0';
const request = require("supertest");
var testData = require('../../test/test_data');

module.exports = function(app, dbclient) {
  app.get(ver + '/dummy', (req, res) => {
    //dummy
    try {         
      //res.status(200).send({result: validation.dateTimeIsValid('2015-aa-25T12:00:00Z')});
      let nJob = JSON.parse(JSON.stringify(testData.jobOK));
      request(app)
      .post(ver + '/jobs')            
      .send(nJob)
      .set('Accept', 'application/json')
      .end(function(err, res) { 
          assert.equal(res.status, 400);
          assert.include(res.body.requestValidationErrors, 'description');
          response.dbclient.close()
      });  
    }
    catch(e) {
      res.status(500).send({error: e.message});
    }
  });   
  app.get('/', (req, res) => {
    //index route
    try {         
      res.status(200).send({appDeployed: true});
    }
    catch(e) {
      res.status(500).send({error: e.message});
    }
  });
}