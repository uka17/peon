// routes/index.js
const dummyRoutes = require('./dummy_routes');
const jobRoutes = require('./job_routes');
const connectionRoutes = require('./connection_routes');
var request = require('request');
const config = require('../../config/config');

/**
 * Main router
 * @param {object} app Express instance
 * @param {object} dbclient DB connection instance
 */
module.exports = function(app, dbclient) {
  dummyRoutes(app, dbclient);
  jobRoutes(app, dbclient);
  connectionRoutes(app, dbclient);
};

function execute() {
  let promis = new Promise((resolve, reject) => {
    request.get({
      url: config.test_host + '/jobs/count', 
      json: true
    },
    function(error, response, body) {
      if(body)  
        resolve(body);
      else
        reject('Error');
    });
  });
  promis.then(resp => { console.log(resp)}, rej => { console.log(rej) })
}

var timerId = setInterval(execute, 1000);