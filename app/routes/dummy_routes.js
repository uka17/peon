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
      schema.jobSchema['required'] = schema.jobSchemaRequired;
      var validate = ajv.compile(schema.jobSchema);      
      var testData = {
        description: 'job description',
        enabled: true,
        steps: []  
    };
                
      var valid = validate(testData);

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