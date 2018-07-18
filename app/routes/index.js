// routes/index.js
const dummyRoutes = require('./dummy_routes');
const jobRoutes = require('./job_routes');
const connectionRoutes = require('./connection_routes');
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