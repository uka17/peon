var errorList = new Array();

module.exports.addError = (err) => { errorList.push(err); };
module.exports.checkErrorList = () => { 
        if(errorList.length > 0) {   
            var errorMessage = new Error(JSON.stringify(errorList));
            errorList = [];
            throw errorMessage;            
        }
    };
