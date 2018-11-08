// routes/dummy_routes.js
var utools = require('../tools/utools');
const config = require('../../config/config');
var validation = require('../tools/validations');
var ver = '/v1.0';
var testData = require('../../test/test_data');
var parseDateTime = require('../schedule/date_time').parseDateTime;
var getDateTime = utools.getDateTime;
var addDate = require('../schedule/date_time').addDate;
var monthList = require('../schedule/date_time').monthList;
var schedule = require('../schedule/schedule');

module.exports = function(app, dbclient) {
  app.get(ver + '/dummy', (req, res) => {
    //dummy
    try {         
      //res.status(200).send({result: validation.dateTimeIsValid('2015-aa-25T12:00:00Z')});
      let scheduleTestObject = testData.monthlyScheduleOK;
      scheduleTestObject.startDateTime = parseDateTime('2018-01-01T10:00:00.000Z');
      scheduleTestObject.month =  monthList.slice(getDateTime().getUTCMonth(), getDateTime().getUTCMonth() + 1);
      scheduleTestObject.day = [getDateTime().getUTCDate()];
      //5 minutes ago
      scheduleTestObject.dailyFrequency = { "occursOnceAt": `${getDateTime().getUTCHours()}:${getDateTime().getMinutes() - 5}:${getDateTime().getSeconds()}` };                         
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