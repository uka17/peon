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
/**
 * Returns new date based on date and added number of years, months, days, hours, minutes or seconds
 * @param {date} date Date value to which days should be added
 * @param {number} years Number of years to add
 * @param {number} months Number of months to add
 * @param {number} days Number of days to add
 * @param {number} hours Number of hours to add
 * @param {number} minutes Number of minutes to add
 * @param {number} seconds Number of seconds to add
 * @returns {date} New date with added number of days
 */
module.exports.addDate = (date, years, months, days, hours, minutes, seconds) =>
{
    let result = new Date(
        date.getFullYear() + years,
        date.getMonth() + months,
        date.getDate() + days,
        date.getHours() + hours,
        date.getMinutes() + minutes,
        date.getSeconds() + seconds
    );
    return result;
}
module.exports.calculateNextRun = (schedule) => {    
    //oneTime
    if(schedule.hasOwnProperty('oneTime')) {        
        return schedule.oneTime;
    }
    //eachNDay 
    if(schedule.hasOwnProperty('eachNDay')) {        
        //calculating date
        let newDateTime = schedule.startDateTime;
        let currentDate = new Date();
        while(newDateTime < currentDate) {
            newDateTime = addDate(newDateTime, 0, 0, schedule.eachNDay, 0, 0, 0);
        }
        //add time
        if(schedule.hasOwnProperty('occursOnceAt')) {
            let time = schedule.dailyFrequency.occursOnceAt.split(':');
            newDateTime.setHours(time[0]);
            newDateTime.setMinutes(time[1]);
            newDateTime.setSeconds(time[2]);
            return newDateTime;
        }
        if(schedule.hasOwnProperty('occursEvery')) {
            let time = schedule.dailyFrequency.start.split(':');
            newDateTime.setHours(time[0]);
            newDateTime.setMinutes(time[1]);
            newDateTime.setSeconds(time[2]);
            while(newDateTime < currentDate) {
                switch(schedule.dailyFrequency.occursEvery.intervalType) {
                    case 'minute':
                        addDate(newDateTime, 0, 0, 0, 0, schedule.dailyFrequency.occursEvery.intervalValue, 0);
                    break;
                    case 'hour':
                        addDate(newDateTime, 0, 0, 0, schedule.dailyFrequency.occursEvery.intervalValue, 0, 0);
                    break;
                }
            }
            return newDateTime;
        }
    }    
    //eachNWeek
    //month
}
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

module.exports.expressMongoInstancePromise = function(router, mongodb_url) {
    let prms = new Promise((resolve, reject) => {
        try {
            MongoClient.connect(mongodb_url, { useNewUrlParser: true }, (err, dbclient) => {
                if (err) 
                    return console.log(err)    
                let app = expressInstance();
                router(app, dbclient);
                resolve({app: app, dbclient: dbclient});
            })
        }
        catch(e2) {
            console.log(e2);
        }            
    });
    return prms;  
}