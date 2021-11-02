// tools/db.js
const config = require("../../config/config");
const { Pool } = require("pg");
const log = require("../../log/dispatcher");

//configure data type mapping postgres-node due to convert postgres data type to correct one at node side
var types = require("pg").types;
types.setTypeParser(20, function (val) {
  return parseInt(val);
});

const sysPool = new Pool({
  "connectionString": config.postgresConnectionString,
  "idleTimeoutMillis": 1000,
  "ssl": config.useDBSSL,
});

/*
pool.on('connect', (client) => {
  log.info("New connection established. Total: " + pool.totalCount);
})
pool.on('remove', (client) => {
  log.info("Connection removed. Total: " + pool.totalCount);
})
*/

/**
 * Rerturns query object
 * @param {Object} query Query for execution
 * @param {string} query.text Text of query with $n placeholders for parameters
 * @param {?string[]} query.values Array of values which should be placed instead of placeholders in text
 * @param {?Function} callback Callback to be called after query is finished
 * @returns {Object} Query object or `Promise` in case if callback is not defined
 */
function executeSysQuery(query, callback) {
  if (callback === undefined) return sysPool.query(query);
  else return sysPool.query(query, callback);
}
module.exports.query = executeSysQuery;

/**
 * Rerturns query object
 * @param {Object} query Query for execution
 * @param {string} query.text Text of query with $n placeholders for parameters
 * @param {?string[]} query.values Array of values which should be placed instead of placeholders in text
 * @param {string} connectionString Connection string to connect to databse
 * @param {?Function} callback Callback to be called after query is finished
 * @returns {Object} Query object or `Promise` in case if callback is not defined or `null` in case of error
 */
function executeUserQuery(query, connectionString, callback) {
  if (connectionString === undefined) {
    log.error(`Connection string was not provided for query '${query.text}'`);
    return null;
  }

  /* istanbul ignore next */
  let userPool = new Pool({
    "connectionString": connectionString,
    "idleTimeoutMillis": 1000,
    "ssl": config.useDBSSL,
  });

  //tested in executeSysQuery
  /* istanbul ignore next */
  if (callback === undefined) return userPool.query(query);
  else return userPool.query(query, callback);
}
module.exports.userQuery = executeUserQuery;
