var errorList = new Array();
//add error to array
module.exports.addError = (err) => { errorList.push(err); };
//throw all errors in case in error array is not empty
module.exports.checkErrorList = () => { 
        if(errorList.length > 0) {   
            var errorMessage = new Error(JSON.stringify(errorList));
            errorList = [];
            throw errorMessage;            
        }
    };
//returns current date-time
module.exports.getTimestamp = () => { 
    return new Date();
}
//rename object property
module.exports.renameProperty = function (obj, oldName, newName) {
    if (obj.hasOwnProperty(oldName)) {
        obj[newName] = obj[oldName];
        delete obj[oldName];
    }
    return obj;
};
//check 
