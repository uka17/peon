// routes/dummy_routes.js
var utools = require('../tools/utools');
const config = require('../../config/config');
var validation = require('../tools/validations');
var ver = '/v1.0';
const request = require("supertest");
var testData = require('../../test/test_data');
var parseDateTime = require('../schedule/date_time').parseDateTime;
var getDateTime = utools.getDateTime;
var addDate = require('../schedule/date_time').addDate;
var schedule = require('../schedule/schedule');

module.exports = function(app, dbclient) {
  app.get(ver + '/dummy', (req, res) => {
    //dummy
    try {         
      //res.status(200).send({result: validation.dateTimeIsValid('2015-aa-25T12:00:00Z')});
      let scheduleTestObject = testData.weeklyScheduleOK;
      scheduleTestObject.startDateTime = addDate(getDateTime(), 0, 0, -35, 0, 0, 0);
      scheduleTestObject.eachNWeek = 3;
      scheduleTestObject.dayOfWeek = ['wed', 'fri'];
      calculationResult = schedule.calculateNextRun(scheduleTestObject);
      res.status(200).send({result: calculationResult});
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