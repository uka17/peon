var userErrorList = new Array();
const MongoClient = require('mongodb').MongoClient;
var Ajv = require('ajv');
//#region Error handling
//add error to array
module.exports.addUserError = (err) => { userErrorList.push(err); };
//throw all errors in case in error array is not empty
module.exports.checkUserErrorList = () => { 
    if(userErrorList !== undefined)
        if(userErrorList.length > 0) {   
            var userErrorList = new Error(JSON.stringify(userErrorList));
            userErrorList.name = 'userError';
            userErrorList = [];
            throw userErrorMessage;            
        }
};
module.exports.checkObject = (object, schema) => {
    var ajv = new Ajv();
    var validate = ajv.compile(schema);
    var valid = validate(object);
    if (!valid) {
      var vErr = new Error(ajv.errorsText(validate.errors));
      vErr.name = 'appError';
      throw vErr;
    }
}
//throw user error
module.exports.throwUserError = (message) => {
    var uErr = new Error(message);
    uErr.name = 'appError';
    throw uErr;
}
//Handle error. I ncase if this is user error - return in to user, otherwise log error and return response with HTTP 500 and logID
module.exports.handleException = function(e, type, createdBy, dbclient, res) {
    if(e.name === 'appError') {
        res.status(500).send({error: e.message});
    }
    else {
        let pr = new Promise((resolve, reject) => {
            logItem = {message: e.message, type: type, createdOn: getTimestamp(), cratedBy: createdBy};
            dbclient.db('peon').collection('log').insert(logItem, (err, result) => {
                if (err)
                    reject(new Error(err));
                else 
                    resolve(result.ops[0]._id);
            });          
        });
        pr.then(
            response => res.status(500).send({error: 'The Lord of Darkness cursed something on our server. We have already called out the Holy Reinforcements and they are trying to fix everything. You can help us to win by sending logId. Amen!', logId: response}),
            error => console.log(error)
            );    
    }
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
