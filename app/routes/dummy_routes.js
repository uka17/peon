// routes/dummy_routes.js
var mongo = require('mongodb');
var utools = require('../tools/utools');
var schema = require('../models/app_models');
const config = require('../../config/config');
var Ajv = require('ajv');
var ajv = new Ajv();
var validation = require('../tools/validation');

module.exports = function(app, dbclient) {
  app.get('/dummy', (req, res) => {
    //dummy
    try {           
      res.status(200).send({result: validation.dateTimeIsValid('2015-aa-25T12:00:00Z')});
    }
    catch(e) {
      res.status(500).send({error: e.message});
    }
  });   
}