// routes/ut_routes.js
var utools = require('../tools/utools');
const config = require('../../config/config');
var validation = require('../tools/validations');
var ver = '/v1.0';

module.exports = function(app, dbclient) {
  app.get(ver + '/handleUserException', (req, res) => {      
      utools.handleUserException('error_message', 400, res);
  });  
  /* istanbul ignore next */
  app.get(ver + '/handleServerException', (req, res) => {
      /* istanbul ignore next */
    utools.handleServerException(new Error('dummyerror'), 'ut', dbclient, res);
});  
}