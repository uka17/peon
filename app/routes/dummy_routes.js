// routes/dummy_routes.js
var mongo = require('mongodb');
var utools = require('../tools/utools');
var schema = require('../models/app_models');
const config = require('../../config/config');
var Ajv = require('ajv');
var ajv = new Ajv();

module.exports = function(app, dbclient) {
  app.get('/dummy', (req, res) => {
    //dummy
    try {           
      //var newSchema = schema.jobSchema;
      //newSchema['required'] = schema.jobSchemaRequiered;

      var validate = ajv.compile(schema.scheduleSchemaDaily);
      var a = {
        eachNDay: 2,
        //dailyFrequency: { occursEvery: {intervalType: 'minute', interval: 4} }
        dailyFrequency: { occursOnceAt: '11:11:65' }
      };

      var valid = validate(a);
      if (valid) 
        res.status(200).send({result: "Valid"});
      else 
        res.status(500).send({error: ajv.errorsText(validate.errors)});
      
    }
    catch(e) {
      res.status(500).send({error: e.message});
    }
  });   
}