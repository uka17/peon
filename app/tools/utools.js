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
 * Return date-time in a proper format
 * @returns {object} Date-time
 */
function getDateTime() { 
    return new Date();
}
module.exports.getDateTime = getDateTime;
/**
 * Extract from date and time and return time in a format HH:MM:SS. Current date time will be taken in case if dateTime is not provided
 * @param {object} dateTime Date and time object which should be used for time extraction
 * @returns {string} Time in a format HH:MM:SS
 */
function getTimefromDateTime(dateTime) { 
    let currentDateTime;
    if(dateTime && dateTime instanceof Date)
        currentDateTime = dateTime;
    else
        currentDateTime = getDateTime();
    let hours = currentDateTime.getHours();
    let minutes = currentDateTime.getMinutes();
    let seconds = currentDateTime.getSeconds();
    hours = hours < 10 ? '0' + hours : hours;
    minutes = minutes < 10 ? '0' + minutes : minutes;
    seconds = seconds < 10 ? '0' + seconds : seconds;    
    return hours + ':' + minutes + ':' + seconds;
}
module.exports.getTimefromDateTime = getTimefromDateTime;
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
 * @param {object} date Date value to which date-time intervals should be added
 * @param {number} years Number of years to add
 * @param {number} months Number of months to add
 * @param {number} days Number of days to add
 * @param {number} hours Number of hours to add
 * @param {number} minutes Number of minutes to add
 * @param {number} seconds Number of seconds to add
 * @returns {object} New date with added number of days
 */
function addDate(date, years, months, days, hours, minutes, seconds) {  
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
module.exports.addDate = addDate;
/**
 * Convert string represented date and time to native date-time format
 * @param {string} stringDateTime Date and time represented as a sting. Example: '2018-01-31T20:54:23.071Z'
 * @returns {datetime} Date and time in a native format
 */
function parseDateTime(stringDateTime) {
    let preDate = Date.parse(stringDateTime);
    if(!isNaN(preDate)) 
        return  new Date(preDate);            
    else
        return null;
}
module.exports.parseDateTime = parseDateTime;
/**
 * Calculates next run date and time 
 * @param {object} schedule Schedule for which next run date and time should be calculated
 * @returns {object} Next run date and time or null in case if next run date and time can not be calculated
 */ 
module.exports.calculateNextRun = (schedule) => {    
    //oneTime
    if(schedule.hasOwnProperty('oneTime')) {        
        let oneTime = parseDateTime(schedule.oneTime);
        if(oneTime > getDateTime())
            return oneTime;
        else
            return null;
    }

    //eachNDay 
    if(schedule.hasOwnProperty('eachNDay')) {        
        //calculating date without time
        let currentDate = new Date((new Date()).setHours(0, 0, 0, 0));
        let newDateTime = new Date(parseDateTime(schedule.startDateTime).setHours(0, 0, 0, 0));
        while(newDateTime < currentDate) {
            newDateTime = addDate(newDateTime, 0, 0, schedule.eachNDay, 0, 0, 0);
        }
        //add time
        if(schedule.dailyFrequency.hasOwnProperty('occursOnceAt')) {
            let time = schedule.dailyFrequency.occursOnceAt.split(':');
            newDateTime.setHours(time[0], time[1], time[2]);
            return newDateTime;
        }
        if(schedule.hasOwnProperty('occursEvery')) {
            let time = schedule.dailyFrequency.start.split(':');
            newDateTime.setHours(time[0], time[1], time[2]);
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