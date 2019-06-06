// routes/dummy_routes.js
var util = require('../tools/util');
const config = require('../../config/config');
var validation = require('../tools/validation');
var ver = '/v1.0';
var testData = require('../../test/test_data');
var messageBox = require('../../config/message_labels')('en');
let db = require('../tools/db');

module.exports = function(app, dbclient) {
  app.get(ver + '/dummy', (req, res) => {
    //dummy
    try {        
      util.handleServerException("Errror!", "sys", dbclient, res);
    }
    catch(e) {
      res.status(500).send({error: e.message});
    }
  });  
  app.get('/', (req, res) => {
    //get jobs count
    try {
      const query = {
        "text": 'SELECT public."fnJob_Count"() as count'
      };
      dbclient.query(query, (err, result) => {
        /* istanbul ignore if */
        if (err) {        
          util.handleServerException(err, config.user, dbclient, res);
        } 
        else {        
          let resObject = {};
          resObject['Greeting:'] = 'Welcome, comrade!';
          resObject['Jobs:'] = result.rows[0].count;
          resObject['Deploy status:'] = 'Ok';
          res.status(200).send(resObject);
        } 
      });
    }
    catch(e) {
      /* istanbul ignore next */
      util.handleServerException(e, config.user, dbclient, res);
    }
  });     
}