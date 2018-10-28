//Schedule main engine
var getDateTime = require('../tools/utools').getDateTime;
var addDate = require('./date_time').addDate;
var parseDateTime = require('./date_time').parseDateTime;

/**
 * Calculates next run time for already calculated day
 * @param {object} schedule Schedule for which next run time should be calculated
 * @param {object} runDate Day of next run with 00:00 time
 * @returns {object} Next run date and time or null in case if next run time is out of runDate range (e.g. attempt to calculate 'each 13 hours' at 19:00) 
 * or already in past (e.g. attempt to calculate '11:00' at 11:05)
 */
function calculateTimeOfRun(schedule, runDate) {  
    let runDateTime = runDate;

    if(schedule.dailyFrequency.hasOwnProperty('occursOnceAt')) {
        let time = schedule.dailyFrequency.occursOnceAt.split(':');
        runDateTime.setUTCHours(time[0], time[1], time[2]); //it should put time in UTC, but it puts it in local        
        if(runDateTime > getDateTime())
            return runDateTime;
        else
            return null;                                   
    }

    if(schedule.dailyFrequency.hasOwnProperty('occursEvery')) {
        let time = schedule.dailyFrequency.start.split(':');
        //milliseconds should be removed?
        runDateTime.setUTCHours(time[0], time[1], time[2], 0);
        while(runDateTime < getDateTime()) {
            //TODO nice to have interval like 03:30 (both hour and minutes)
            switch(schedule.dailyFrequency.occursEvery.intervalType) {
                case 'minute':
                    runDateTime = addDate(runDateTime, 0, 0, 0, 0, schedule.dailyFrequency.occursEvery.intervalValue);
                break;
                case 'hour':
                    runDateTime = addDate(runDateTime, 0, 0, 0, schedule.dailyFrequency.occursEvery.intervalValue);
                break;
            }
        }
        if(runDate.getUTCDate() == runDateTime.getUTCDate())
            return runDateTime;   
        else
            return null;
        
    }
}
/**
 * Scans week which starts with weekStart and tries to find date for run
 * @param {object} schedule Schedule for which next run time should be calculated
 * @param {object} weekStart Date of sunday (0 day of week)
 * @returns {object} Date or next run or null in case if date was not calculated
 */
function calculateWeekDayOfRun(schedule, weekStart) {
    let currentDay = weekStart;
    let weekDayList = ["sun", "mon", "tue", "wed", "thu", "fri", "sat"];
    let weekDayLastIndex = 0;
    for (let i = 0; i < schedule.dayOfWeek.length; i++) {
        let weekDayIndex = weekDayList.indexOf(schedule.dayOfWeek[i]);
        if(weekDayIndex != -1) {
            currentDay = addDate(currentDay, 0, 0, weekDayIndex - weekDayLastIndex);
            weekDayLastIndex = weekDayIndex;
            //day calculating time found - don't go next
            let calculationResult = calculateTimeOfRun(schedule, currentDay);
            if(calculationResult) {            
                if(calculationResult > schedule.startDateTime)
                    return calculationResult;
                currentDay = calculationResult;
            }
        }        
    }   
    return null;
}
/**
 * Calculates next run date and time 
 * @param {object} schedule Schedule for which next run date and time should be calculated
 * @returns {object} Next run date and time or null in case if next run date and time can not be calculated
 */ 
module.exports.calculateNextRun = (schedule) => { 
    ///TODO process ENABLED property  
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
            newDateTime = addDate(newDateTime, 0, 0, schedule.eachNDay);
        }        
        //as far as day was found - start to search moment in a day for run
        result = calculateTimeOfRun(schedule, newDateTime);
        
        //day overwhelming after adding interval or already happend, go to future, to next N day
        if(result == null) {
            newDateTime = addDate(newDateTime, 0, 0, schedule.eachNDay);
            newDateTime.setUTCHours(0, 0, 0, 0);
            result = calculateTimeOfRun(schedule, newDateTime);
        }
    }    
    //eachNWeek
    if(schedule.hasOwnProperty('eachNWeek')) {               
        //due to save milliseconds and not link newDateTime object with schedule.startDateTime
        let newDateTime = new Date(parseDateTime(schedule.startDateTime));
        newDateTime.setUTCHours(0, 0, 0, 0);
        //find Sunday of start week 
        newDateTime = addDate(newDateTime, 0, 0, -newDateTime.getUTCDay());
        //make start point as Sunday of start week + (eachNWeek-1) weeks due to find first sunday for checking            
        newDateTime = addDate(newDateTime, 0, 0, 7*(schedule.eachNWeek - 1));
        //find Sunday of current week    
        let currentDate = new Date((new Date()).setUTCHours(0, 0, 0, 0));
        let currentWeekSunday = addDate(currentDate, 0, 0, -currentDate.getUTCDay());            
        //find Sunday of week where next run day(s) are        
        while(newDateTime < currentWeekSunday) {
            newDateTime = addDate(newDateTime, 0, 0, 7*schedule.eachNWeek);
        }          
        
        let calculationResult = calculateWeekDayOfRun(schedule, newDateTime);
        if(calculationResult)
            newDateTime = calculationResult;

        //as far as begining of the week was found - start to search day for execution
        while(newDateTime < schedule.startDateTime || newDateTime < getDateTime()) {
            newDateTime = addDate(newDateTime, 0, 0, 7*schedule.eachNWeek);   
            calculationResult = calculateWeekDayOfRun(schedule, newDateTime);       
            if(calculationResult)
                newDateTime = calculationResult;
        }         
        result = newDateTime;      
    }  
    //month
    if(schedule.hasOwnProperty('month')) {                               
        let monthList = ["jan", "feb", "mar", "apr", "may", "jun", "jul", "aug", "sep", "oct", "nov", "dec"];
        let newDateTime = new Date(parseDateTime(schedule.startDateTime));
        newDateTime.setUTCHours(0, 0, 0, 0);
        let runMonth = null;
        let monthIndex = getDateTime().getMonth();
        for(let i=0; i<13; i++) {
            if(schedule.month.includes(monthList[monthIndex])) {
                //check days  
                runMonth = monthIndex;
                break;
            }
            monthIndex++;
            if(monthIndex == 12) {
                monthIndex = 0;
                newDateTime = addDate(newDateTime, 1);
            }
        }    
        
        let dayList = schedule.day.sort();            
        for(let i=0; i<dayList.length; i++) {
            newDateTime.setMonth(runMonth, dayList[i]);
            //as far as day was found - start to search moment in a day for run
            if(newDateTime > getDateTime()) {
                newDateTime = calculateTimeOfRun(schedule, newDateTime);
                //happend, but already past or date overwhelming
                if(newDateTime < getDateTime() || newDateTime == null) {
                    let me =1;
                }
                result = newDateTime;
                break;
            }
        }
     
    }     
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