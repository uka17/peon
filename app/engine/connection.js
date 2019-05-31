// engine/connection.js
const dbclient = require("../tools/db");
const log = require('../../log/dispatcher');

/**
 * Returns connection by id
 * @param {number} connectionId Id of connection
 * @returns {Promise} Promise which returns connection in case of success and `null` in case of failure 
 */
function getConnection(connectionId) {
  return new Promise((resolve, reject) => {
    const query = {
      "text": 'SELECT public."fnConnection_Select"($1) as connection',
      "values": [connectionId]
    };
    dbclient.query(query, (err, result) => {  
      /* istanbul ignore if */
      if (err) {
        log.error(`Failed to get connection by id=${connectionId}. Stack: ${err.stack}`);
      } else {
        if(result.rows[0].connection == null) {
          log.warn(`No any connection found by id=${connectionId}`);
          reject(null);
        }
        else
          resolve(result.rows[0].connection);
      } 
    });
  });
}

