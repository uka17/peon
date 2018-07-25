// routes/dummy_routes.js
var mongo = require('mongodb');
var utools = require('../tools/utools');
var schema = require('../models/app_models');
const config = require('../../config/config');
var Ajv = require('ajv');
var ajv = new Ajv();
var validation = require('../tools/validations');
var ver = '/v1.0';

module.exports = function(app, dbclient) {
  app.get(ver + '/dummy', (req, res) => {
    //dummy
    try {         
      res.status(200).send({result: validation.dateTimeIsValid('2015-aa-25T12:00:00Z')});
    }
    catch(e) {
      res.status(500).send({error: e.message});
    }
  });   
  app.get(ver + '/dummyerror', (req, res) => {
    //dummyerror
    try {
      throw new Error('dummyerror');
    }
    catch(e) {
      utools.handleServerException(e, config.user, dbclient, res);
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