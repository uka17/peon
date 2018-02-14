var userErrorList = new Array();
const MongoClient = require('mongodb').MongoClient;
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
//log error and return response with HTTP 500  and logID
module.exports.log = function(message, type, createdBy, dbclient, res) {
    let pr = new Promise((resolve, reject) => {
        logItem = {message: message, type: type, createdOn: getTimestamp(), cratedBy: createdBy};
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
