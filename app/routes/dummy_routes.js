// routes/dummy_routes.js
var mongo = require('mongodb');
var utools = require('../tools/utools');
var schema = require('../models/job');
var Ajv = require('ajv');
const user = "test";

module.exports = function(app, dbclient) {
  app.get('/dummy', (req, res) => {
    //dummy
    try {       
      var ajv = new Ajv();
      var validate = ajv.compile(schema.jobSchema);
      var a = {name: "abc"}

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
};