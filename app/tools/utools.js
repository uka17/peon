var userErrorList = new Array();
const MongoClient = require('mongodb').MongoClient;
var Ajv = require('ajv');
const config = require('../../config/config');
//#region Error handling
module.exports.checkObject = (object, schema, res) => {
    var ajv = new Ajv();
    var validate = ajv.compile(schema);
    var valid = validate(object);
    if (!valid) {
      res.status(400).send(ajv.errorsText(validate.errors));
    }
}

//Handle server error - log error and return response with HTTP 500 and logID
module.exports.handleServerException = function(e, createdBy, dbclient, res) {
    let pr = new Promise((resolve, reject) => {
        try {
            logItem = {error: e, createdOn: getTimestamp(), cratedBy: createdBy};
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
        response => res.status(500).send({error: 'The Lord of Darkness cursed something on our server. We have already called out the Holy Reinforcements and they are trying to fix everything. You can help us to win by sending logId. Amen!', logId: response}),
        error => console.log(error)
        );    
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
