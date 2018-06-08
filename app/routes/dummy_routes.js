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
      //schema.scheduleSchema['required'] = schema.scheduleSchemaDaily;
      ajv.addSchema(schema.scheduleSchemaDaily);
      var validate = ajv.compile(schema.scheduleSchema);      
      var testData = {
        name: 'dailyOnce',
        enabled: true,
        eachNDay: 1,
        dailyFrequency: { occursOnceAt: '11:11:99'}
    };
                
      var valid = validate(testData);

      if (valid) 
        res.status(200).send({result: "Valid"});
      else 
        res.status(500).send({error: validate.errors});
      
    }
    catch(e) {
      res.status(500).send({error: e.message});
    }
  });   
}