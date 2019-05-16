const dbclient = require('../../app/tools/db');
const config = require('../../config/config');
const messageBox = require('../../config/message_labels');
const bodyParser = require('body-parser');
const express = require('express');

var toJSON = require( 'utils-error-to-json' );
//#region Error handling
/**
 * Server error handler. Shows error in console, returns error in response in case if global debug flag is TRUE else
 * puts log in DB and returns Id of log to user 
 * @param {object} e Exception to be handled     
 * @param {string} createdBy Under whose credentials app thrown this exception
 * @param {object} dbclient DB connections instance
 * @param {object} res Response handler
 */
/* istanbul ignore next */
module.exports.handleServerException = function(e, createdBy, dbclient, res) {    
    /* istanbul ignore next */
    if(config.debugMode == "ASDAS") {
        console.log(e);
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
                console.log(e2);
            }
                
        });
        pr.then(
            response => res.status(500).send({error: messageBox.common.debugMessage, logId: response.rows[0].logid}),
            error => console.log(error)
        );    
    }
}
/**
 * Shows user error with proper HTTP response code
 * @param {string} message Error message
 * @param {number} errorCode HTTP response code
 * @param {object} res Response handler 
 */
module.exports.handleUserException = function(message, errorCode, res) {
    res.status(errorCode).send({error: message});
}
//#endregion
/**
 * Renames all properties in object which are equal to oldName
 * @param {object} obj Object to be modified
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
 * Return date-time in a proper format
 * @returns {object} Date-time
 */
function getDateTime() { 
    return new Date();
}
module.exports.getDateTime = getDateTime;
/**
 * Convert string represented date and time to native date-time format
 * @param {string} stringDateTime UTC date and time represented as a sting. Example: '2018-01-31T20:54:23.071Z'
 * @returns {datetime} Date and time object
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
 * Return minimal date-time from array of date time. Not date-time values will be ignored.
 * @param {array} dateTimeList List of string date-time values where to search minimal value
 * @returns {object} Date-time minimal value
 */
function getMinDateTime(dateTimeList) { 
    let castedDateTimeList = dateTimeList.map(parseDateTime).filter(val => val != null);    
    return new Date(Math.min(...castedDateTimeList));
}
module.exports.getMinDateTime = getMinDateTime;
/**
 * Returns new express instance, prepared for work with json
 * @returns {object}
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
 * @param {object} router Object with api routes description
 * @returns {object} Object with app and dbclient
 */
module.exports.expressPostgreInstance = function(router) {
    let app = expressInstance();
    router(app, dbclient);
    return {"app": app, "dbclient": dbclient};   
}