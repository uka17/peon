//Schedule main engine
var getDateTime = require('../tools/utools').getDateTime;
var addDate = require('./date_time').addDate;
var parseDateTime = require('./date_time').parseDateTime;

/**
 * Calculates next run time for already calculated day
 * @param {object} schedule Schedule for which next run time should be calculated
 * @param {object} newDateTime Day of next run with 00:00 time
 * @returns {object} Next run date and time or null in case if next run date and time can not be calculated
 */
function calculateTimeOfRun(schedule, newDateTime) {  
    if(schedule.dailyFrequency.hasOwnProperty('occursOnceAt')) {
        let time = schedule.dailyFrequency.occursOnceAt.split(':');
        newDateTime.setUTCHours(time[0], time[1], time[2]); //it should put time in UTC, but it puts it in local
        if(newDateTime < getDateTime())
            //happened today, but already missed
            newDateTime = addDate(newDateTime, 0, 0, schedule.eachNDay, 0, 0, 0);
        
        return newDateTime;                     
    }

    if(schedule.dailyFrequency.hasOwnProperty('occursEvery')) {
        let time = schedule.dailyFrequency.start.split(':');
        //milliseconds should be removed?
        newDateTime.setUTCHours(time[0], time[1], time[2], 0);
        //remember initial day for overwhelming check
        let initialDay = newDateTime.getDate();
        while(newDateTime < getDateTime()) {
            //TODO nice to have interval like 03:30 (both hour and minutes)
            switch(schedule.dailyFrequency.occursEvery.intervalType) {
                case 'minute':
                    newDateTime = addDate(newDateTime, 0, 0, 0, 0, schedule.dailyFrequency.occursEvery.intervalValue, 0);
                break;
                case 'hour':
                    newDateTime = addDate(newDateTime, 0, 0, 0, schedule.dailyFrequency.occursEvery.intervalValue, 0, 0);
                break;
            }
            if(initialDay < newDateTime.getDate()) {
                newDateTime = addDate(newDateTime, 0, 0, schedule.eachNDay - 1, 0, 0, 0);
                newDateTime.setUTCHours(time[0], time[1], time[2]);
            }
        }
        return newDateTime;   
    }
}

/**
 * Calculates next run date and time 
 * @param {object} schedule Schedule for which next run date and time should be calculated
 * @returns {object} Next run date and time or null in case if next run date and time can not be calculated
 */ 
module.exports.calculateNextRun = (schedule) => {   
    let result = null; 
    //oneTime
    if(schedule.hasOwnProperty('oneTime')) {        
        let oneTime = schedule.oneTime;
        if(oneTime > getDateTime())
            result = oneTime;
    }

    //eachNDay 
    if(schedule.hasOwnProperty('eachNDay')) {        
        //searching for a day of run        
        let currentDate = new Date((new Date()).setUTCHours(0, 0, 0, 0));
        //due to save milliseconds and not link newDateTime object with schedule.startDateTime
        let newDateTime = new Date(parseDateTime(schedule.startDateTime));
        newDateTime.setUTCHours(0, 0, 0, 0);
        while(newDateTime < currentDate) {
            newDateTime = addDate(newDateTime, 0, 0, schedule.eachNDay, 0, 0, 0);
        }        
        //as far as day was found - start to search moment in a day for run
        result = calculateTimeOfRun(schedule, newDateTime);

        if(newDateTime < getDateTime() && schedule.dailyFrequency.hasOwnProperty('occursOnceAt'))
            //happened today, but already missed
            newDateTime = addDate(newDateTime, 0, 0, schedule.eachNDay, 0, 0, 0);
        
    }    
    //eachNWeek
    if(schedule.hasOwnProperty('eachNWeek')) {        
        //searching for a day of run        
        let currentDate = new Date((new Date()).setUTCHours(0, 0, 0, 0));
        //due to save milliseconds and not link newDateTime object with schedule.startDateTime
        let newDateTime = new Date(parseDateTime(schedule.startDateTime));

        //make start point as Sunday of start week
        let dayOfWeek = newDateTime.getDay();
        if(dayOfWeek > 0) 
            newDateTime = addDate(newDateTime, 0, 0, -dayOfWeek, 0, 0, 0);

        //find Sunday of current week    
        let currentWeekSunday = currentDate.getDay();
        if(currentWeekSunday > 0) 
            currentWeekStartDay = addDate(currentDate, 0, 0, -currentWeekSunday, 0, 0, 0);            
        else
            currentWeekStartDay = currentDate;
        
        //find Sunday of week where next run day(s) are        
        while(newDateTime < currentWeekStartDay) {
            newDateTime = addDate(newDateTime, 0, 0, 7, 0, 0, 0);
        }                

        //as far as week was found - start to search day for execution
        newDateTime.setUTCHours(0, 0, 0, 0);
        let weekDayList = ["sun", "mon", "tue", "wed", "thu", "fri", "sat"];
        for (let i = 0; i < weekDayList.length; i++) {
            if(currentDate.getDay()) {
                let i = 0;
            }
        }

        //as far as day was found - start to search moment in a day for run
        result = calculateTimeOfRun(schedule, newDateTime);
    }  
    //month
    //check
    if(schedule.endDateTime) {
        if(result)
            return result > schedule.endDateTime ? null : result;
        else
            return null;
    }
    else
        return result;

}