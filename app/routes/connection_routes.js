// routes/connection_routes.js
var mongo = require('mongodb');
var utools = require('../tools/utools');
var validation = require('../tools/validation');
const config = require('../../config/config');
const messageBox = require('../../config/message_labels');
var ver = '/v1.0';

module.exports = function(app, dbclient) {
  app.get(ver + '/connections/count', (req, res) => {
    //get connections count
    try {
      dbclient.db(config.db_name).collection('connection').countDocuments(req.body, function(err, count) {
        if (err) {        
          utools.handleServerException(err, config.user, dbclient, res);
        } 
        else {        
          let resObject = {};
          resObject[messageBox.common.count] = count;
          res.status(200).send(resObject);
        } 
      });
    }
    catch(e) {
      utools.handleServerException(e, config.user, dbclient, res);
    }
  });
  app.get(ver + '/connections', (req, res) => {
    //get all connections
    try {
      dbclient.db(config.db_name).collection('connection').find(req.body).toArray(function(err, result) {
        if (err) {
          utools.handleServerException(err, config.user, dbclient, res);
        } else {        
          res.status(200).send(result);
        } 
      });
    }
    catch(e) {
      utools.handleServerException(e, config.user, dbclient, res);
    }
  });
  app.get(ver + '/connections/:id', (req, res) => {    
    //get connection by id
    try {
      const where = { '_id': new mongo.ObjectID(req.params.id) };
      dbclient.db(config.db_name).collection('connection').findOne(where, (err, item) => {
        if (err) {
          utools.handleServerException(err, config.user, dbclient, res);
        } else {
          res.status(200).send(item);
        } 
      });
    }
    catch(e) {
      utools.handleServerException(e, config.user, dbclient, res);
    }
  });
  app.post(ver + '/connections', (req, res) => {
    //create new connection
    try {
      const connection = req.body;
      let connectionValidationResult = validation.validateConnection(connection);
      if(!connectionValidationResult.isValid)
        res.status(400).send({requestValidationErrors: connectionValidationResult.errorList});
      else {
        connection.createdOn = utools.getTimestamp();     
        connection.createdBy = config.user;       
        connection.modifiedOn = utools.getTimestamp();    
        connection.modifiedBy = config.user;

        dbclient.db(config.db_name).collection('connection').insert(connection, (err, result) => {
        if (err) { 
          utools.handleServerException(err, config.user, dbclient, res);
        } else {
          res.status(201).send(result.ops[0]);
        }
        });
      }
    }
    catch(e) {
      utools.handleServerException(e, config.user, dbclient, res);
    }
  });

  app.post(ver + '/connections/:id', (req, res) => {
    res.sendStatus(405);
  });
  
  app.patch(ver + '/connections/:id', (req, res) => {
    //update connection by id
    try {
      var connection = req.body;      
      connection.modifiedOn = utools.getTimestamp();
      connection.modifiedBy = config.user;      

      const where = { '_id': new mongo.ObjectID(req.params.id) };      
      const update = { $set: connection};

      dbclient.db(config.db_name).collection('connection').updateOne(where, update, (err, result) => {
        if (err) {
          utools.handleServerException(err, config.user, dbclient, res);
        } else {
          let resObject = {};
          resObject[messageBox.common.updated] = result.result.n;
          res.status(200).send(resObject);
        } 
      });
    }
    catch(e) {
      utools.handleServerException(e, config.user, dbclient, res);
    }
  });
  app.delete(ver + '/connections/:id', (req, res) => {
    //delete connection by _id
    try {
      const where = { '_id': new mongo.ObjectID(req.params.id) };
      dbclient.db(config.db_name).collection('connection').deleteOne(where, (err, result) => {
        if (err) {
          utools.handleServerException(err, config.user, dbclient, res);
        } else {
          let resObject = {};
          resObject[messageBox.common.deleted] = result.result.n;
          res.status(200).send(resObject);          
        } 
      });
    }
    catch(e) {
      utools.handleServerException(e, config.user, dbclient, res);
    }
  });    
};
//TODO
//user handling
//selectors for connection list - protect from injection