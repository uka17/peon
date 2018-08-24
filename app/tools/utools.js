const MongoClient = require('mongodb').MongoClient;
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
    if(config.debugMode) {
        console.log(e);
        res.status(500).send(toJSON(e));
    }    
    else {
        let pr = new Promise((resolve, reject) => {
            try {
                logItem = {error: toJSON(e), createdOn: getDateTime(), cratedBy: createdBy};
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
 * 
 * @param {object} router Object with api routes description
 * @param {string} mongodbUrl MongoDB connection URL
 * @returns {object} Promise which will be resolved just after mongoDB connection
 */
module.exports.expressMongoInstancePromise = function(router, mongodbUrl) {
    let prms = new Promise((resolve, reject) => {
        try {
            MongoClient.connect(mongodbUrl, { useNewUrlParser: true }, (err, dbclient) => {
                /* istanbul ignore next */
                if (err) {                    
                    console.log(err);
                    return null;
                }
                let app = expressInstance();
                router(app, dbclient);
                resolve({app: app, dbclient: dbclient});
            })
        }
        catch(e2) {
            /* istanbul ignore next */
            console.log(e2);
            /* istanbul ignore next */
            return null;
        }            
    });
    return prms;  
}