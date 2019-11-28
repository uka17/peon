const dbclient = require('./db');
const logDispatcher = require('../../log/dispatcher');
const messageBox = require('../../config/message_labels')('en');
const bodyParser = require('body-parser');
const express = require('express');

var toJSON = require( 'utils-error-to-json' );
//#region Error handling
/**
 * Server error handler. Shows error in console, returns error in response in case if global debug flag is TRUE else
 * puts log in DB and returns Id of log to user 
 * @param {Object} e Exception to be handled     
 * @param {string} createdBy Under whose credentials app thrown this exception
 * @param {Object} dbclient DB connections instance
 * @param {Object} res Response handler
 */
/* istanbul ignore next */
module.exports.handleServerException = function(e, createdBy, dbclient, res) {    
  /* istanbul ignore next */
  if(process.env.NODE_ENV !== "PROD") {
    logDispatcher.error(e.stack);
    res.status(500).send(toJSON(e));
  }    
  else {
    let pr = new Promise((resolve, reject) => {
      try {
        const query = {
          "text": 'SELECT public."fnLog_Insert"($1, $2, $3) as logId',
          "values": [1, toJSON(e), createdBy]
        };                  

        dbclient.query(query, (err, result) => {
          if (err)
            reject(new Error(err));
          else 
            resolve(result);
        });  
      }
      catch(e2) {
        logDispatcher.error(e2);
      }
                
    });
    pr.then(
      response => res.status(500).send({error: messageBox.common.debugMessage, logId: response.rows[0].logid}),
      error => logDispatcher.error(error)
    );    
  }
};
module.exports.logServerError = function(e, createdBy) {    
  /* istanbul ignore next */
  if(process.env.NODE_ENV !== "PROD") {
    logDispatcher.error(e.stack);
  }    
  return new Promise((resolve, reject) => {
    const query = {
      "text": 'SELECT public."fnLog_Insert"($1, $2, $3) as logId',
      "values": [1, toJSON(e), createdBy]
    };                  

    dbclient.query(query, (err, result) => {
      try {
        if (err) {
          logDispatcher.error(err);
          resolve(0);
        }
        else 
          resolve(result.rows[0].logid);
      }      
      catch(e2) {
        /* istanbul ignore next */
        logDispatcher.error(e2.stack);
        /* istanbul ignore next */
        resolve(0);
      }   
    });              
  });
};
/**
 * Shows user error with proper HTTP response code
 * @param {string} message Error message
 * @param {number} errorCode HTTP response code
 * @param {Object} res Response handler 
 */
module.exports.handleUserException = function(message, errorCode, res) {
  res.status(errorCode).send({error: message});
};
//#endregion
/**
 * Renames all properties in object which are equal to oldName
 * @param {Object} obj Object to be modified
 * @param {string} oldName Name of property to be renamed
 * @param {string} newName New name for property
 */
module.exports.renameProperty = function (obj, oldName, newName) {
  /* istanbul ignore else */
  if (obj.hasOwnProperty(oldName)) {
    obj[newName] = obj[oldName];
    delete obj[oldName];
  } 
  return obj;
};
/**
 * Return `date-time` in a proper format
 * @returns {Object} `date-time`
 */
function getDateTime() { 
  return new Date();
}
module.exports.getDateTime = getDateTime;

/**
 * Convert string represented `date-time` to native format
 * @param {string} stringDateTime UTC `date-time` represented as a `sting`. Example: `2018-01-31T20:54:23.071Z`
 * @returns {Object} `date-time`
 */
function parseDateTime(stringDateTime) {
  let preDate = Date.parse(stringDateTime);
  if(!isNaN(preDate)) 
    return new Date(preDate);            
  else
    return null;
}
module.exports.parseDateTime = parseDateTime;

/**
 * Return minimal value from array of `date-time`. Not `date-time` values will be ignored.
 * @param {string[]} dateTimeList List of string `date-time` values where to search minimal value
 * @returns {Object} `date-time`
 */
function getMinDateTime(dateTimeList) { 
  let castedDateTimeList = dateTimeList.map(parseDateTime).filter(val => val != null);    
  return new Date(Math.min(...castedDateTimeList));
}
module.exports.getMinDateTime = getMinDateTime;
/**
 * Returns new express instance, prepared for work with `json`
 * @returns {Object}
 */
function expressInstance() {
  const app = express();
  app.use(bodyParser.json());
  app.use(function (req, res, next) {
    res.header("Content-Type",'application/json');
    next();
  });    
  return app;
}
module.exports.expressInstance = expressInstance;

/**
 * Returns object contains both app and dbclient
 * @param {Object} router Object with api routes description
 * @returns {Object} Object with app and dbclient
 */
module.exports.expressPostgreInstance = function(router) {
  let app = expressInstance();
  router(app, dbclient);
  return {"app": app, "dbclient": dbclient};   
};

/**
 * Checks if `value` is a number. Returns `defaultNumber` otherwise.
 * @param {number} value Number which should be checked
 * @param {number} defaultNumber Number which will be returned in case if `value` is not a number
 */
function isNumber(value, defaultNumber) {
  let intVal = parseInt(value);
  if(isNaN(intVal))
    return defaultNumber;
  else
    return intVal;
}
module.exports.isNumber = isNumber;
/**
 * Generates pagination info object
 * @param {string} baseUrl URL which will be used for generating `next_page_url` and `next_page_url`
 * @param {number} perPage Number of records per page
 * @param {number} page Current page number
 * @param {number} count Total number of records
 * @param {string} filter Filter part
 * @param {string} sort Sorting part
 */
function pagination(baseUrl, perPage, page, count, filter, sort) {
  let result = {};
  let lastPage = Math.ceil(count / perPage);
  let nextPage = (page == lastPage) ? null : page + 1;
  let prevPage = (page == 1) ? null : page - 1;
  let filterExpression = (filter === undefined) ? '' : `&filter=${filter}`;
  let sortExpression = (sort === undefined) ? '' : `&sort=${sort}`;
  result.total = count;
  result.per_page = perPage;
  result.current_page = page;
  result.last_page = lastPage;
  result.next_page_url = (nextPage === null) ? null : `${baseUrl}/?page=${nextPage}&per_page=${perPage}${filterExpression}${sortExpression}`;
  result.prev_page_url = (prevPage === null) ? null : `${baseUrl}/?page=${prevPage}&per_page=${perPage}${filterExpression}${sortExpression}`;
  result.from = perPage*(page-1) + 1;
  if(page == lastPage)
    result.to = count;
  else
    result.to = perPage*page;
  return result;
}
module.exports.pagination = pagination;
