// routes/ut_routes.js
var util = require('../tools/util');
var ver = '/v1.0';

module.exports = function(app, dbclient) {
  app.get(ver + '/handleUserException', (req, res) => {      
    util.handleUserException('error_message', 400, res);
  });  
  /* istanbul ignore next */
  app.get(ver + '/handleServerException', (req, res) => {
    /* istanbul ignore next */
    util.handleServerException(new Error('dummyerror'), 'ut', dbclient, res);
  });  
}