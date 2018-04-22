// routes/dummy_routes.js
var mongo = require('mongodb');
var utools = require('../tools/utools');
var schema = require('../models/job');
const config = require('../../config/config');
var Ajv = require('ajv');

module.exports = function(app, dbclient) {
  app.get('/dummy', (req, res) => {
    //dummy
    try {       
      var ajv = new Ajv();
      var validate = ajv.compile(schema.scheduleSchema);
      var a = {
        name: 'name',
        recurrent: {
          occurs: 'weekly',
          recursEvery: 1,
          dayOfWeek: ['Monday', 'Wednesday']
        } 
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
};