// routes/connection_routes.js
var utools = require('../tools/utools');
var validation = require('../tools/validations');
const config = require('../../config/config');
const messageBox = require('../../config/message_labels');
var ver = '/v1.0';

module.exports = function(app, dbclient) {
  app.get(ver + '/connections/count', (req, res) => {
    //get connections count
    try {
      const query = {
        "text": 'SELECT public."fnConnection_Count"() as count'
      };
      dbclient.query(query, (err, result) => {
        /* istanbul ignore if */
        if (err) {        
          utools.handleServerException(err, config.user, dbclient, res);
        } 
        else {        
          let resObject = {};
          resObject[messageBox.common.count] = result.rows[0].count;
          res.status(200).send(resObject);
        } 
      });
    }    
    catch(e) {
      /* istanbul ignore next */
      utools.handleServerException(e, config.user, dbclient, res);
    }
  });
  app.get(ver + '/connections', (req, res) => {
    //get all connections
    try {
      const query = {
        "text": 'SELECT public."fnConnection_SelectAll"() as connections'
      };
      //TODO validation before insert or edit
      dbclient.query(query, (err, result) => {   
        /* istanbul ignore if */
        if (err) {
          utools.handleServerException(err, config.user, dbclient, res);
        } else {        
          res.status(200).send(result.rows[0].connections);
        } 
      });
    }    
    catch(e) {
      /* istanbul ignore next */
      utools.handleServerException(e, config.user, dbclient, res);
    }
  });
  app.get(ver + '/connections/:id', (req, res) => {    
    //get connection by id
    try {
      const query = {
        "text": 'SELECT public."fnConnection_Select"($1) as connection',
        "values": [req.params.id]
      };
      //TODO validation before insert or edit
      dbclient.query(query, (err, result) => {  
        /* istanbul ignore if */
        if (err) {
          utools.handleServerException(err, config.user, dbclient, res);
        } else {
          if(result.rows[0].connection == null)
            res.status(404).send();
          else
            res.status(200).send(result.rows[0].connection);
        } 
      });
    }
    catch(e) {
      /* istanbul ignore next */
      utools.handleServerException(e, config.user, dbclient, res);
    }
  });
  app.post(ver + '/connections', (req, res) => {
    //create new connection
    try {
      const connection = req.body;
      let connectionValidationResult = validation.validateConnection(connection);
      if(!connectionValidationResult.isValid)
        res.status(400).send({"requestValidationErrors": connectionValidationResult.errorList});
      else {
        const query = {
          "text": 'SELECT public."fnConnection_Insert"($1, $2) as id',
          "values": [connection, config.user]
        };
        dbclient.query(query, (err, result) => {       
          /* istanbul ignore if */
          if (err) { 
            utools.handleServerException(err, config.user, dbclient, res);
          } else {
            connection.id = result.rows[0].id;
            res.status(201).send(connection);
          }
        });
      }
    }
    catch(e) {
      /* istanbul ignore next */
      utools.handleServerException(e, config.user, dbclient, res);
    }
  });

  app.post(ver + '/connections/:id', (req, res) => {
    res.sendStatus(405);
  });
  
  app.patch(ver + '/connections/:id', (req, res) => {
    //update connection by id
    try {
      const query = {
        "text": 'SELECT public."fnConnection_Update"($1, $2, $3) as count',
        "values": [req.params.id, req.body, config.user]
      };
      dbclient.query(query, (err, result) => {     
        /* istanbul ignore if */
        if (err) {
          utools.handleServerException(err, config.user, dbclient, res);
        } else {
          let resObject = {};
          resObject[messageBox.common.updated] = result.rows[0].count;
          res.status(200).send(resObject);
        } 
      });
    }
    catch(e) {
      /* istanbul ignore next */
      utools.handleServerException(e, config.user, dbclient, res);
    }
  });
  app.delete(ver + '/connections/:id', (req, res) => {
    //delete connection by _id
    try {
      const query = {
        "text": 'SELECT public."fnConnection_Delete"($1) as count',
        "values": [req.params.id]
      };
      //TODO validation before insert or edit
      dbclient.query(query, (err, result) => {  
        /* istanbul ignore if */
        if (err) {
          utools.handleServerException(err, config.user, dbclient, res);
        } else {
          let resObject = {};
          resObject[messageBox.common.deleted] = result.rows[0].count;
          res.status(200).send(resObject);          
        } 
      });
    }
    catch(e) {
      /* istanbul ignore next */
      utools.handleServerException(e, config.user, dbclient, res);
    }
  });    
};
//TODO
//user handling
//selectors for connection list - protect from injection