// routes/dummy_routes.js
var mongo = require('mongodb');
var utools = require('../tools/utools');
var schema = require('../models/app_models');
const config = require('../../config/config');
//var Ajv = require('ajv');

module.exports = function(app, dbclient) {
  app.get('/dummy', (req, res) => {
    //dummy
    try {       
      var ajv = new Ajv();
      var validate = ajv.compile(schema.scheduleSchema);
      var a = {
        name: 'name',
        occurs: {
          recurrentType: 'oneTime', 
          onceAt: '2016-05-18T16:00:00Z'
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
app.get('/dummy1', (req, res) => {
  var Ajv = require('ajv');
  var ajv = new Ajv({allErrors: true});
  
  var schema = {
    "type": "object",
    "properties": {
      "occurs": {
        "type": "object", 
        "properties": { 
          "recurrentType": { "enum": ["oneTime", "daily"] }
        },      
        "if": { "properties": { "recurrentType": {"const": "oneTime"}}},
        "then": { 
          "properties": {"onceAt": {"type": "string", "format": "date-time"}},
          "required": ["onceAt"]
        },
        "else": {
            "properties": { "recursEvery": {"type": "integer", "minimum": 1}},
            "required": ["recursEvery"] 
        }, 
        "additionalProperties": false   //For some unknown reason it doesn't work. Ajv considers correct properties as additional inside IF
      }
    }
  };
  
  var validate = ajv.compile(schema);
  
  test({"occurs": {
            "recurrentType": "oneTime", 
            "onceAt": "2016-05-18T16:00:00Z"
          } });
  
  function test(data) {
    var valid = validate(data);
    if (valid) console.log('Valid!');
    else console.log('Invalid: ' + ajv.errorsText(validate.errors));
  }
});

app.get('/dummy', (req, res) => {
    //dummy
    try {       
      var ajv = new Ajv();
      var validate = ajv.compile(schema.testSchema);
      var a = {
        occurs: {
          recurrentType: 'oneTime', 
          onceAt: '2016-05-18T16:00:00Z'
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