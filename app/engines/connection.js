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
        /* istanbul ignore if */
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
        /* istanbul ignore next */
        log.error(`Failed to get conneciton count with query ${query}. Stack: ${e}`);        
        /* istanbul ignore next */
        reject(e);
      }     
    });
  });
}
module.exports.getConnectionCount = getConnectionCount;

/**
 * Returns Connection list accordingly to filtering, sorting, page order and page number
 * @param {string} filter Filter will be applied to `name` and `description` columns
 * @param {string} sortColumn Name of sorting column
 * @param {string} sortOrder Sorting order (`asc` or `desc`)
 * @param {number} perPage Number of records per page
 * @param {number} page Page number
 * @returns {Promise} Promise which resolves with list of `Connection` objects in case of success, `null` if Connection list is empty and rejects with error in case of failure
 */
function getConnectionList(filter, sortColumn, sortOrder, perPage, page) {
  return new Promise((resolve, reject) => {
    try 
    {
      if(sortOrder !== 'asc' && sortOrder !== 'desc')
        throw new TypeError('sortOrder should have value `asc` or `desc`');
      if(typeof parseInt(perPage) !== 'number' || isNaN(parseInt(perPage)))
        throw new TypeError('perPage should be a number');        
      if(typeof parseInt(page) !== 'number' || isNaN(parseInt(page)))
        throw new TypeError('page should be a number');  
      const query = {
        "text": 'SELECT public."fnConnection_SelectAll"($1, $2, $3, $4, $5) as connections',
        "values": [filter, sortColumn, sortOrder, parseInt(perPage), parseInt(page)]
      };
      dbclient.query(query, (err, result) => {  
        try {
          /* istanbul ignore if */
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
        catch(e) /*istanbul ignore next*/ {        
          log.error(`Failed to get conneciton list with query ${query}. Stack: ${e}`);        
          reject(e);
        }       
    });
  }
  catch(err) {
    log.error(`Parameters type mismatch. Stack: ${err}`);              
    reject(err);   
  }
  });
}
module.exports.getConnectionList = getConnectionList;

/**
 * Returns Connection by id
 * @param {number} connectionId Id of connection
 * @returns {Promise} Promise which returns Connection object in case of success, `null` in case if object not found by `id` and rejects with error in case of failure
 */
function getConnection(connectionId) {
  return new Promise((resolve, reject) => {
    try {
      if(typeof parseInt(connectionId) !== 'number' || isNaN(parseInt(connectionId)))
        throw new TypeError('connectionId should be a number');     
      const query = {
        "text": 'SELECT public."fnConnection_Select"($1) as connection',
        "values": [parseInt(connectionId)]
      };
      dbclient.query(query, (err, result) => {  
        try {
          /* istanbul ignore if */
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
        catch(e) /*istanbul ignore next*/ {        
          log.error(`Failed to get conneciton with query ${query}. Stack: ${e}`);        
          reject(e);
        }        
      });
    } 
    catch(err) {
      log.error(`Parameters type mismatch. Stack: ${err}`);              
      reject(err);   
    }    
  });
}
module.exports.getConnection = getConnection;

/**
 * Creates new Connection
 * @param {Object} connection Connection object to be created
 * @param {string?} createdBy User who created connection
 * @returns {Promise} Promise which resolves with just created Connection object populated with `id` in case of success and rejects with error in case of failure
 */
function createConnection(connection, createdBy) {
  return new Promise((resolve, reject) => {
    try {
      if(typeof connection !== 'object')
        throw new TypeError('connection should be an object');   
      if(typeof createdBy !== 'string')
        throw new TypeError('createdBy should be a string');      
      const query = {
        "text": 'SELECT public."fnConnection_Insert"($1, $2) as id',
        "values": [connection, createdBy]
      };
      dbclient.query(query, async (err, result) => {           
        try { 
          /* istanbul ignore if */
          if (err) { 
            throw new Error(err);
          } else {
            let newBornConnection = await getConnection(result.rows[0].id);
            resolve(newBornConnection);
          }
        }
        catch(e) /*istanbul ignore next*/ {        
          log.error(`Failed to insert conneciton with query ${query}. Stack: ${e}`);        
          reject(e);
        }   
      });
    } 
    catch(err) {
      log.error(`Parameters type mismatch. Stack: ${err}`);              
      reject(err);   
    }        
  });
}
module.exports.createConnection = createConnection;

/**
 * Updates Connection by `id`
 * @param {number} connectionId Id of Connection
 * @param {Object} connection Content by which Connection object should be updated
 * @param {string} updatedBy User who updates connection
 * @returns {Promise} Promise which resolves with number of updated rows in case of success and rejects with error in case of failure 
 */
function updateConnection(connectionId, connection, updatedBy) {
  return new Promise((resolve, reject) => {
    try {
      if(typeof parseInt(connectionId) !== 'number' || isNaN(parseInt(connectionId)))
        throw new TypeError('connectionId should be a number');     
      if(typeof connection !== 'object')
        throw new TypeError('connection should be an object');    
      if(typeof updatedBy !== 'string')
        throw new TypeError('updatedBy should be a string');     
      const query = {
        "text": 'SELECT public."fnConnection_Update"($1, $2, $3) as count',
        "values": [parseInt(connectionId), connection, updatedBy]
      };
      dbclient.query(query, async (err, result) => {           
        try { 
          /* istanbul ignore if */
          if (err) { 
            throw new Error(err);
          } else {    
            resolve(result.rows[0].count);
          }
        }
        catch(e) /*istanbul ignore next*/ {        
          log.error(`Failed to update conneciton with query ${query}. Stack: ${e}`);        
          reject(e);
        }  
      });
    }
    catch(err) {
      log.error(`Parameters type mismatch. Stack: ${err}`);              
      reject(err);   
    }     
  });
}
module.exports.updateConnection = updateConnection;

/**
 * Marks Connection as deleted by id
 * @param {number} connectionId Id of connection to be deleted
 * @param {string} deletedBy Who did this?
 * @returns {Promise} Promise which resolves with number of deleted rows in case of success and rejects with error in case of failure 
 */
function deleteConnection(connectionId, deletedBy) {
  return new Promise((resolve, reject) => {
    try {
      if(typeof parseInt(connectionId) !== 'number' || isNaN(parseInt(connectionId)))
        throw new TypeError('connectionId should be a number');   
      if(typeof deletedBy !== 'string')
        throw new TypeError('deletedBy should be a string');     
      const query = {
        "text": 'SELECT public."fnConnection_Delete"($1, $2) as count',
        "values": [parseInt(connectionId), deletedBy]
      };
      dbclient.query(query, async (err, result) => {           
        try { 
          /* istanbul ignore if */
          if (err) { 
            throw new Error(err);
          } else {    
            resolve(result.rows[0].count);
          }
        }
        catch(e) /*istanbul ignore next*/ {        
          log.error(`Failed to delete conneciton with query ${query}. Stack: ${e}`);        
          reject(e);
        }  
      });
    }
    catch(err) {
      log.error(`Parameters type mismatch. Stack: ${err}`);              
      reject(err);   
    }      
  });
}
module.exports.deleteConnection = deleteConnection;