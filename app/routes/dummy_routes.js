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
      let scheduleTestObject = testData.dailyScheduleOnceOK;
      scheduleTestObject.startDateTime = utools.addDate(utools.getDateTime(), 0, 0, -15, 0, 0, 0);
      scheduleTestObject.eachNDay = 7;
      let nextRunDateTime = utools.addDate(utools.getDateTime(), 0, 0, 6, 0, 15, 0); 
      //nextRunDateTime.setMilliseconds(0);
      scheduleTestObject.dailyFrequency.occursOnceAt = utools.getTimefromDateTime(nextRunDateTime);
      res.status(200).send({result: utools.calculateNextRun(scheduleTestObject)});
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