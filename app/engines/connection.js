/* eslint-disable no-unused-vars */
/* eslint-disable no-case-declarations */
/* eslint-disable no-prototype-builtins */
// engine/connection.js
const dbclient = require("../tools/db");
const log = require('../../log/dispatcher');

/**
 * Returns Connection count accordingly to filtering
 * @param {string} filter Filter will be applied to `name` and `description` columns
 * @returns {Promise} Promise which resolves with numeber of `Connection` objects in case of success, `null` if Connection list is empty and rejects with error in case of failure
 */
function getConnectionCount(filter) {
  return new Promise((resolve, reject) => {
    const query = {
      "text": 'SELECT public."fnConnection_Count"($1) as count',
      "values": [filter]
    };
    dbclient.query(query, (err, result) => {  
      try {
        if (err) {
          throw new Error(err);
        } else {
        /* istanbul ignore if */
          if(result.rows[0].count == null) {
            resolve(null);
          }
          else
            resolve(result.rows[0].count);
        }
      }
      catch(e) {        
        log.error(`Failed to get conneciton count with query ${query}. Stack: ${e}`);        
        reject(e);
      }     
    });
  });
}
module.exports.getConnectionCount = getConnectionCount;

/**
 * Returns Connection list accordingly to filtering, sorting and page order and number
 * @param {string} filter Filter will be applied to text columns
 * @param {string} sortColumn Name of sorting column
 * @param {string} sortOrder Sorting order (`asc` or `desc`)
 * @param {number} perPage Number of record per page
 * @param {number} page Page number
 * @returns {Promise} Promise which resolves with list of `Connection` objects in case of success, `null` if Connection list is empty and rejects with error in case of failure 
 */
function getConnectionList(filter, sortColumn, sortOrder, perPage, page) {
  return new Promise((resolve, reject) => {
    const query = {
      "text": 'SELECT public."fnConnection_SelectAll"($1, $2, $3, $4, $5) as Connections',
      "values": [filter, sortColumn, sortOrder, perPage, page]
    };
    dbclient.query(query, (err, result) => {  
      try {
        if (err) {
          throw new Error(err);
        } else {
        /* istanbul ignore if */
          if(result.rows[0].connections == null) {
            resolve(null);
          }
          else
            resolve(result.rows[0].connections);
        } 
      }
      catch(e) {        
        log.error(`Failed to get conneciton list with query ${query}. Stack: ${e}`);        
        reject(e);
      }       
    });
  });
}
module.exports.getConnectionList = getConnectionList;

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
      try {
        if (err) {
          throw new Error(err);
        } else {
        /* istanbul ignore if */
          if(result.rows[0].connection == null) {
            resolve(null);
          }
          else
            resolve(result.rows[0].connection);
        } 
      }
      catch(e) {        
        log.error(`Failed to get conneciton with query ${query}. Stack: ${e}`);        
        reject(e);
      }        
    });
  });
}
module.exports.getConnection = getConnection;

/**
 * Creates new connection in DB
 * @param {Object} connection Connection object to be created in DB
 * @param {string?} createdBy User who creates connection
 * @returns {Promise} Promise which resolves with just created connection with `id` in case of success and rejects with error in case of failure
 */
function createConnection(connection, createdBy) {
  return new Promise((resolve, reject) => {
    const query = {
      "text": 'SELECT public."fnConnection_Insert"($1, $2) as id',
      "values": [connection, createdBy]
    };
    dbclient.query(query, async (err, result) => {           
      try { 
        if (err) { 
          throw new Error(err);
        } else {
          let newBornConnection = await getConnection(result.rows[0].id);
          resolve(newBornConnection);
        }
      }
      catch(e) {        
        log.error(`Failed to insert conneciton with query ${query}. Stack: ${e}`);        
        reject(e);
      }   
    });
  });
}
module.exports.createConnection = createConnection;

/**
 * Updates connection in DB by id
 * @param {number} connectionId Id of connection to be updated
 * @param {Object} connection Connection object to be updated with
 * @param {string} updatedBy User who updates connection
 * @returns {Promise} Promise which resolves with number of updated rows in case of success and rejects with error in case of failure 
 */
function updateConnection(connectionId, connection, updatedBy) {
  return new Promise((resolve, reject) => {
    const query = {
      "text": 'SELECT public."fnConnection_Update"($1, $2, $3) as count',
      "values": [connectionId, connection, updatedBy]
    };
    dbclient.query(query, async (err, result) => {           
      try { 
        if (err) { 
          throw new Error(err);
        } else {    
          resolve(result.rows[0].count);
        }
      }
      catch(e) {        
        log.error(`Failed to update conneciton with query ${query}. Stack: ${e}`);        
        reject(e);
      }  
    });
  });
}
module.exports.updateConnection = updateConnection;

/**
 * Marks connection in DB as deleted by id
 * @param {number} connectionId Id of connection to be deleted
 * @param {string} deletedBy User updateConnectionNextRunho deletes connection
 * @returns {Promise} Promise which resolves with number of deleted rows in case of success and rejects with error in case of failure 
 */
function deleteConnection(connectionId, deletedBy) {
  return new Promise((resolve, reject) => {
    const query = {
      "text": 'SELECT public."fnConnection_Delete"($1, $2) as count',
      "values": [connectionId, deletedBy]
    };
    dbclient.query(query, async (err, result) => {           
      try { 
        if (err) { 
          throw new Error(err);
        } else {    
          resolve(result.rows[0].count);
        }
      }
      catch(e) {        
        log.error(`Failed to delete conneciton with query ${query}. Stack: ${e}`);        
        reject(e);
      }  
    });
  });
}
module.exports.deleteConnection = deleteConnection;