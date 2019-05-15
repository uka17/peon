// tools/db.js
const config = require('../../config/config');
const { Pool } = require('pg')

//configure data type mapping postgres-node due to convert postgres data type to correct one at node side
var types = require('pg').types;
types.setTypeParser(20, function(val) {
  return parseInt(val)
})

const pool = new Pool({
  "connectionString": config.connectionString, 
  "idleTimeoutMillis": 1000, 
  "ssl": config.useDBSSL })
pool.on('connect', (client) => {
  console.log("New connection established. Total: " + pool.totalCount);
})
pool.on('remove', (client) => {
  console.log("Connection removed. Total: " + pool.totalCount);
})

module.exports = {
  query: (query, callback) => {
    return pool.query(query, callback)
  }  
}
module.exports.pool = pool;