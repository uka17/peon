//Schedule main engine
var getDateTime = require('../tools/utools').getDateTime;
var addDate = require('./date_time').addDate;
var parseDateTime = require('./date_time').parseDateTime;

/**
 * Calculates next run date and time 
 * @param {object} schedule Schedule for which next run date and time should be calculated
 * @returns {object} Next run date and time or null in case if next run date and time can not be calculated
 */ 
module.exports.calculateNextRun = (schedule) => {    
    //oneTime
    if(schedule.hasOwnProperty('oneTime')) {        
        let oneTime = schedule.oneTime;
        if(oneTime > getDateTime())
            return oneTime;
        else
            return null;
    }

    //eachNDay 
    if(schedule.hasOwnProperty('eachNDay')) {        
        let currentDate = new Date((new Date()).setUTCHours(0, 0, 0, 0));
        //due to save milliseconds and not link newDateTime object with schedule.startDateTime
        let newDateTime = new Date(parseDateTime(schedule.startDateTime));
        newDateTime.setUTCHours(0, 0, 0, 0);
        let endDateTime = schedule.endDateTime ? schedule.endDateTime : undefined;
        while(newDateTime < currentDate) {
            newDateTime = addDate(newDateTime, 0, 0, schedule.eachNDay, 0, 0, 0);
        }        
        if(schedule.dailyFrequency.hasOwnProperty('occursOnceAt')) {
            let time = schedule.dailyFrequency.occursOnceAt.split(':');
            newDateTime.setUTCHours(time[0], time[1], time[2]); //it should put time in UTC, but it puts it in local
            if(newDateTime < getDateTime())
                //happened today, but already missed
                newDateTime = addDate(newDateTime, 0, 0, schedule.eachNDay, 0, 0, 0);
            
            if(newDateTime > endDateTime)
                return null;
            else {
                //return milliseconds back
                newDateTime.setMilliseconds(schedule.startDateTime.getMilliseconds());
                return newDateTime;   
            }                         
        }

        if(schedule.dailyFrequency.hasOwnProperty('occursEvery')) {
            let time = schedule.dailyFrequency.start.split(':');
            newDateTime.setHours(time[0], time[1], time[2]);
            while(newDateTime < getDateTime()) {
                switch(schedule.dailyFrequency.occursEvery.intervalType) {
                    case 'minute':
                        newDateTime = addDate(newDateTime, 0, 0, 0, 0, schedule.dailyFrequency.occursEvery.intervalValue, 0);
                    break;
                    case 'hour':
                        newDateTime = addDate(newDateTime, 0, 0, 0, schedule.dailyFrequency.occursEvery.intervalValue, 0, 0);
                    break;
                }
            }
        
            if(newDateTime > endDateTime)
                return null;
            else
                return newDateTime;   
        }
    }    
    //eachNWeek
    //month
}