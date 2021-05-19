// routes/connection_routes.js
var util = require('../tools/util');
var validation = require('../tools/validation');
let connectionEngine = require('../engines/connection');
const restConfig = require('../../config/rest_config');
const config = require('../../config/config');
const labels = require('../../config/message_labels')('en');
var ver = '/v1.0';

module.exports = function(app, dbclient) {
  app.get(ver + '/connections/count', async (req, res) => {
    //get connection count
    try {
      let filter;

      if(req.query.filter !== undefined)
        filter = req.query.filter;
      else 
        filter = '';      

      let result = await connectionEngine.getConnectionCount(filter);
      /* istanbul ignore if */
      if(result == null)
        res.status(404).send();
      else {
        let resObject = {};
        resObject[labels.common.count] = result;
        res.status(200).send(resObject);
      }
    }
    catch(e) {      
      /* istanbul ignore next */
      let logId = await util.logServerError(e, config.user);
      /* istanbul ignore next */
      res.status(500).send({error: labels.common.debugMessage, logId: logId});
    }
  });

  app.get(ver + '/connections', async (req, res) => {
    //get all connections
    try {
      let filter, sortingExpression, perPage, page;
      if(req.query.sort !== undefined) {
        sortingExpression = req.query.sort.split('|');
        if(sortingExpression.length == 1)
          sortingExpression.push('asc');
      }
      else 
        sortingExpression = ['id', 'asc'];
      
      if(req.query.filter !== undefined)
        filter = req.query.filter;
      else 
        filter = '';
      
      perPage = util.isNumber(req.query.per_page, restConfig.defaultPerPage);
      page = util.isNumber(req.query.page, 1);

      let result = await connectionEngine.getConnectionList(filter, sortingExpression[0], sortingExpression[1], perPage, page);
      /* istanbul ignore if */
      if(result == null)
        res.status(204).send();
      else {
        let wrappedResult = JSON.parse(JSON.stringify(restConfig.templates.selectAll));
        let connectionCount = await connectionEngine.getConnectionCount(filter);
        wrappedResult.data = result;
        let url = `${req.protocol}://${req.get('host')}${req._parsedUrl.pathname}`;
        wrappedResult.pagination = util.pagination(url, perPage, page, connectionCount, req.query.filter, req.query.sort);

        res.status(200).send(wrappedResult);
      }
    }
    catch(e) {      
      /* istanbul ignore next */
      let logId = await util.logServerError(e, config.user);
      /* istanbul ignore next */
      res.status(500).send({error: labels.common.debugMessage, logId: logId});
    }
  });

  app.get(ver + '/connections/:id', async (req, res) => { 
    //get connection by id
    try {
      let result = await connectionEngine.getConnection(req.params.id);
      if(result == null)
        res.status(404).send();
      else
        res.status(200).send(result);
    }
    catch(e) {      
      /* istanbul ignore next */
      let logId = await util.logServerError(e, config.user);
      /* istanbul ignore next */
      res.status(500).send({error: labels.common.debugMessage, logId: logId});
    }
  });

  app.post(ver + '/connections', async (req, res) => {
    //create new connection
    try {
      const connection = req.body;
      let connectionValidationResult = validation.validateConnection(connection);
      if(!connectionValidationResult.isValid)
        res.status(400).send({"requestValidationErrors": connectionValidationResult.errorList});
      else {
        let result = await connectionEngine.createConnection(connection, config.user);
        res.status(201).send(result);
      }
    }
    catch(e) {      
      /* istanbul ignore next */
      let logId = await util.logServerError(e, config.user);
      /* istanbul ignore next */
      res.status(500).send({error: labels.common.debugMessage, logId: logId});
    }
  });

  app.post(ver + '/connections/:id', (req, res) => {
    res.sendStatus(405);
  });
  
  app.patch(ver + '/connections/:id', async (req, res) => {
    //update connection by id
    try {
      const connection = req.body;
      let connectionValidationResult = validation.validateConnection(connection);

      /* istanbul ignore if */
      if(!connectionValidationResult.isValid)
        res.status(400).send({"requestValidationErrors": connectionValidationResult.errorList});
      else {
        let result = await connectionEngine.updateConnection(req.params.id, connection, config.user);
        let resObject = {};
        resObject[labels.common.updated] = result;
        res.status(200).send(resObject);
      }
    }
    /* istanbul ignore next */
    catch(e) {      
      /* istanbul ignore next */
      let logId = await util.logServerError(e, config.user);
      /* istanbul ignore next */
      res.status(500).send({error: labels.common.debugMessage, logId: logId});
    }
  });

  app.delete(ver + '/connections/:id', async (req, res) => {
    //delete connection by _id
    try {
      let result = await connectionEngine.deleteConnection(req.params.id, config.user);
      let resObject = {};
      resObject[labels.common.deleted] = result;
      res.status(200).send(resObject);
    }
    /* istanbul ignore next */
    catch(e) {      
      /* istanbul ignore next */
      let logId = await util.logServerError(e, config.user);
      /* istanbul ignore next */
      res.status(500).send({error: labels.common.debugMessage, logId: logId});
    }  
  });    
};
//TODO
//user handling
//selectors for connection list - protect from injection