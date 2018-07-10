var userErrorList = new Array();
const MongoClient = require('mongodb').MongoClient;
const config = require('../../config/config');
const messageBox = require('../../config/message_labels');
var toJSON = require( 'utils-error-to-json' );
//#region Error handling
//Handle server error - log error and return response with HTTP 500 and logID
module.exports.handleServerException = function(e, createdBy, dbclient, res) {
    if(config.debugMode) {
        console.log(toJSON(e));
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
//Handle error user error - return in to user.
module.exports.handleUserException = function(message, errorCode, res) {
    res.status(errorCode).send({error: message});
}
//#endregion
//returns current date-time
var getTimestamp = () => { 
    return new Date();
}
module.exports.getTimestamp = getTimestamp;
//rename object property
module.exports.renameProperty = function (obj, oldName, newName) {
    if (obj.hasOwnProperty(oldName)) {
        obj[newName] = obj[oldName];
        delete obj[oldName];
    }
    return obj;
};
