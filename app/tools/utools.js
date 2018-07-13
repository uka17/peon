const MongoClient = require('mongodb').MongoClient;
const config = require('../../config/config');
const messageBox = require('../../config/message_labels');
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
module.exports.handleServerException = function(e, createdBy, dbclient, res) {
    if(config.debugMode) {
        console.log(e);
        res.status(500).send(toJSON(e));
    }
    else {
        let pr = new Promise((resolve, reject) => {
            try {
                logItem = {error: toJSON(e), createdOn: getTimestamp(), cratedBy: createdBy};
                dbclient.db(config.db_name).collection('log').insert(logItem, (err, result) => {
                    if (err)
                        reject(new Error(err));
                    else 
                        resolve(result.ops[0]._id);
                });  
            }
            catch(e2) {
                console.log(e2);
            }
                
        });
        pr.then(
            response => res.status(500).send({error: messageBox.common.debugMessage, logId: response}),
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
 * Return date-time in a proper format
 * @returns {datetime} Date-time
 */
var getTimestamp = () => { 
    return new Date();
}
module.exports.getTimestamp = getTimestamp;
/**
 * Renames all properties in object which are equal to oldName
 * @param {object} obj Object to be modified
 * @param {string} oldName Name of property to be renamed
 * @param {string} newName New name for property
 */
module.exports.renameProperty = function (obj, oldName, newName) {
    if (obj.hasOwnProperty(oldName)) {
        obj[newName] = obj[oldName];
        delete obj[oldName];
    }
    return obj;
};
