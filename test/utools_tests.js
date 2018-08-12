//utools unit tests
var chai  = require('chai');
chai.use(require('chai-datetime'))
var assert  = chai.assert;


var utools = require('../app/tools/utools');
const request = require("supertest");
var ver = '/v1.0';
var ut_routes = require('../app/routes/ut_routes');
const app = utools.expressInstance();
ut_routes(app);

describe('utools', function() {
    describe('errors handling', function() {
        it('handleUserException ', function(done) {            
            request(app)
            .get(ver + '/handleUserException')            
            .end(function(err, res) { 
                assert.equal(res.status, 400);
                assert.include(res.body.error, 'error_message');
                done();
              });              
        });
    });

    describe('small tools and helpers', function() {
        it('getDateTime ', function(done) {            
            assert.equalDate(utools.getDateTime(), new Date());
            assert.equalTime(utools.getDateTime(), new Date());
            done();
        });   
        it('getTimefromDateTime. date provided and leading zeroes', function(done) {
            let dateTime = utools.parseDateTime('2018-01-31T02:03:04.071Z');
            assert.equal(utools.getTimefromDateTime(dateTime), '02:03:04');
            done();
        });           
        it('getTimefromDateTime. date provided and no need to add leading zeroes', function(done) {
            let dateTime = utools.parseDateTime('2018-01-31T12:13:14.071Z');
            assert.equal(utools.getTimefromDateTime(dateTime), '12:13:14');
            done();
        });                   
        it('getTimefromDateTime. date is not provided', function(done) {
            assert.include( (new Date()).toUTCString(), utools.getTimefromDateTime()); 
            done();
        });           
        it('renameProperty', function(done) {
            let expected = {new_name: 'obj_name', val: 1};
            let initial = {name: 'obj_name', val: 1};
            assert.equal(utools.renameProperty(initial, 'name', 'new_name').toString(), expected.toString());
            done();
        });  
        it('addDate 1+', function(done) {
            let expected = utools.parseDateTime('2018-01-31T02:02:02.071Z');            
            let initial = utools.parseDateTime('2018-01-31T01:01:01.071Z');
            initial = utools.addDate(initial, 0, 0, 0, 1, 1, 1);
            assert.equal(initial.toDateString(), expected.toDateString());
            done();
        });         
        it('addDate 2+', function(done) {
            let initial = utools.parseDateTime('2018-02-28T23:00:00.000Z');            
            let expected = utools.parseDateTime('2018-03-01T01:00:00.000Z');
            initial = utools.addDate(initial, 0, 0, 0, 2, 0, 0);
            assert.equal(initial.toDateString(), expected.toDateString());
            done();
        });            
        it('addDate 3+', function(done) {
            let initial = utools.parseDateTime('2018-06-10T02:02:02.071Z');            
            let expected = utools.parseDateTime('2019-06-10T02:02:02.071Z');
            initial = utools.addDate(initial, 1, 0, 0, 0, 0, 0);
            assert.equal(initial.toDateString(), expected.toDateString());
            done();
        });             
        it('addDate 4-', function(done) {
            let expected = utools.parseDateTime('2018-01-31T01:01:01.000Z');            
            let initial = utools.parseDateTime('2018-01-31T02:02:02.000Z');
            initial = utools.addDate(initial, 0, 0, 0, -1, -1, -1);
            assert.equal(initial.toDateString(), expected.toDateString());
            done();
        });         
        it('addDate 5-', function(done) {
            let initial = utools.parseDateTime('2018-05-01T01:00:00.000Z');            
            let expected = utools.parseDateTime('2018-04-30T23:00:00.000Z');
            initial = utools.addDate(initial, 0, 0, 0, -2, 0, 0);
            assert.equalDate(initial, expected);
            assert.equalTime(initial, expected);
            done();
        });            
        it('addDate 6-', function(done) {
            let initial = utools.parseDateTime('2019-06-10T02:02:02.071Z');            
            let expected = utools.parseDateTime('2018-06-10T02:02:02.071Z');
            initial = utools.addDate(initial, -1, 0, 0, 0, 0, 0);
            assert.equal(initial.toDateString(), expected.toDateString());
            done();
        });                 
        it('parseDateTime. success', function(done) {
            let dateTime = new Date(Date.parse('2019-06-10T02:02:02.071Z'));
            assert.equalDate(utools.parseDateTime('2019-06-10T02:02:02.071Z'), dateTime);
            assert.equalTime(utools.parseDateTime('2019-06-10T02:02:02.071Z'), dateTime);
            done();
        });        
        it('parseDateTime. failure', function(done) {
            assert.isNull(utools.parseDateTime(true));
            done();
        });                  
    });

    describe('calculateNextRun', function() {
        describe('oneTime', function() {
            it('success. added time', function(done) {
                let scheduleTestObject = require('./test_data').oneTimeScheduleOK;
                scheduleTestObject.oneTime = utools.addDate(utools.getDateTime(), 0, 0, 0, 3, 0, 0);
                let nextRun = scheduleTestObject.oneTime;
                assert.equalDate(utools.calculateNextRun(scheduleTestObject), nextRun);
                assert.equalTime(utools.calculateNextRun(scheduleTestObject), nextRun);
                done();
            });         
            it('success. added date', function(done) {
                let scheduleTestObject = require('./test_data').oneTimeScheduleOK;
                scheduleTestObject.oneTime = utools.addDate(utools.getDateTime(), 0, 0, 1, 0, 0, 0);
                let nextRun = scheduleTestObject.oneTime;
                assert.equalDate(utools.calculateNextRun(scheduleTestObject), nextRun);
                assert.equalTime(utools.calculateNextRun(scheduleTestObject), nextRun);
                done();
            });      
            it('failure. not a date', function(done) {
                let scheduleTestObject = require('./test_data').oneTimeScheduleOK;
                scheduleTestObject.oneTime = true;
                assert.isNull(utools.calculateNextRun(scheduleTestObject));
                done();
            });                                               
        });

        describe('eachNDay. occursOnceAt', function() {
            it('success. run at now+5min', function(done) {
                let scheduleTestObject = require('./test_data').dailyScheduleOnceOK;
                scheduleTestObject.startDateTime = utools.getDateTime();
                scheduleTestObject.eachNDay = 1;
                let nextRunDateTime = utools.addDate(utools.getDateTime(), 0, 0, 0, 0, 0, 5); //test will fail between 23:55:00 and 00:00:00
                scheduleTestObject.dailyFrequency.occursOnceAt = utools.getTimefromDateTime(nextRunDateTime);
                let calculationResult = utools.calculateNextRun(scheduleTestObject);
                console.log('str: ', scheduleTestObject.startDateTime);
                console.log('end: ', scheduleTestObject.endDateTime);
                console.log('crn: ', utools.getDateTime());                
                console.log('int: ', scheduleTestObject.eachNDay);
                console.log('clc: ', calculationResult);
                console.log('exp: ', nextRunDateTime);                
                assert.equalDate(calculationResult, nextRunDateTime);
                assert.equalTime(calculationResult, nextRunDateTime);
                done();
            });      
            it('success. run every 7 days at now+15min', function(done) {
                let scheduleTestObject = require('./test_data').dailyScheduleOnceOK;
                scheduleTestObject.startDateTime = utools.addDate(utools.getDateTime(), 0, 0, -15, 0, 0, 0);
                scheduleTestObject.eachNDay = 7;
                let nextRunDateTime = utools.addDate(utools.getDateTime(), 0, 0, 6, 0, 0, 15); 
                scheduleTestObject.dailyFrequency.occursOnceAt = utools.getTimefromDateTime(nextRunDateTime);
                let calculationResult = utools.calculateNextRun(scheduleTestObject);
                console.log('str: ', scheduleTestObject.startDateTime);
                console.log('end: ', scheduleTestObject.endDateTime);
                console.log('crn: ', utools.getDateTime());                
                console.log('int: ', scheduleTestObject.eachNDay);
                console.log('clc: ', calculationResult);
                console.log('exp: ', nextRunDateTime);                
                assert.equalDate(calculationResult, nextRunDateTime);
                assert.equalTime(calculationResult, nextRunDateTime);
                done();
            });             
            it('success. run at now+1day-1hour', function(done) {
                let scheduleTestObject = require('./test_data').dailyScheduleOnceOK;
                scheduleTestObject.startDateTime = utools.addDate(utools.getDateTime(), 0, 0, -1, -1, 0, 0);
                scheduleTestObject.eachNDay = 1;
                let nextRunDateTime = utools.addDate(utools.getDateTime(), 0, 0, 1, -1, 0, 0);
                scheduleTestObject.dailyFrequency.occursOnceAt = utools.getTimefromDateTime(nextRunDateTime);
                let calculationResult = utools.calculateNextRun(scheduleTestObject);
                console.log('str: ', scheduleTestObject.startDateTime);
                console.log('end: ', scheduleTestObject.endDateTime);
                console.log('crn: ', utools.getDateTime());                
                console.log('int: ', scheduleTestObject.eachNDay);
                console.log('clc: ', calculationResult);
                console.log('exp: ', nextRunDateTime);                
                assert.equalDate(calculationResult, nextRunDateTime);
                assert.equalTime(calculationResult, nextRunDateTime);
                done();
            });               
            it('failure. endDateTime restriction', function(done) {
                let scheduleTestObject = require('./test_data').dailyScheduleOnceOK;
                scheduleTestObject.startDateTime = utools.addDate(utools.getDateTime(), 0, 0, -1, -1, 0, 0);
                scheduleTestObject.eachNDay = 1;
                scheduleTestObject.endDateTime = utools.getDateTime();
                let nextRunDateTime = utools.addDate(utools.getDateTime(), 0, 0, 1, -1, 0, 0);
                scheduleTestObject.dailyFrequency.occursOnceAt = utools.getTimefromDateTime(nextRunDateTime);
                let calculationResult = utools.calculateNextRun(scheduleTestObject);
                console.log('str: ', scheduleTestObject.startDateTime);
                console.log('end: ', scheduleTestObject.endDateTime);
                console.log('crn: ', utools.getDateTime());                
                console.log('int: ', scheduleTestObject.eachNDay);
                console.log('clc: ', calculationResult);
                console.log('exp: ', nextRunDateTime);              
                assert.isNull(calculationResult);
                done();
            });                     
        });

        describe('eachNDay. occursEvery', function() {
            it('success. run every 15 minutes starting 10:07:00', function(done) {
                //test data preparation
                let scheduleTestObject = require('./test_data').dailyScheduleEveryOK;
                scheduleTestObject.startDateTime = utools.parseDateTime('2018-01-01T10:00:00.000Z');
                scheduleTestObject.eachNDay = 1;                
                scheduleTestObject.dailyFrequency.start = '10:07:00';
                scheduleTestObject.dailyFrequency.occursEvery.intervalType = 'minute';
                scheduleTestObject.dailyFrequency.occursEvery.intervalValue = 15;
                //calculate test case data
                let calculationResult = utools.calculateNextRun(scheduleTestObject);
                //manual calculation for validation
                let time = scheduleTestObject.dailyFrequency.start.split(':');
                let nextRunDateTime = new Date(utools.getDateTime().setHours(time[0], time[1], time[2], 0));
                while(nextRunDateTime < utools.getDateTime()) {
                    nextRunDateTime = utools.addDate(nextRunDateTime, 0, 0, 0, 0, scheduleTestObject.dailyFrequency.occursEvery.intervalValue, 0);
                }
                //log
                console.log('str: ', scheduleTestObject.startDateTime);
                console.log('end: ', scheduleTestObject.endDateTime);
                console.log('crn: ', utools.getDateTime());                
                console.log('int: ', scheduleTestObject.eachNDay);
                console.log('frc: ', scheduleTestObject.dailyFrequency.start, scheduleTestObject.dailyFrequency.occursEvery.intervalType, scheduleTestObject.dailyFrequency.occursEvery.intervalValue);
                console.log('clc: ', calculationResult);
                console.log('exp: ', nextRunDateTime);   
                //assertion
                assert.equalDate(calculationResult, nextRunDateTime);
                assert.equalTime(calculationResult, nextRunDateTime);
                done();
            });          
            it('success. run every 5 hours starting 05:55:00', function(done) {
                //test data preparation
                let scheduleTestObject = require('./test_data').dailyScheduleEveryOK;
                scheduleTestObject.startDateTime = utools.parseDateTime('2018-01-01T10:00:00.000Z');
                scheduleTestObject.eachNDay = 1;                
                scheduleTestObject.dailyFrequency.start = '05:55:00';
                scheduleTestObject.dailyFrequency.occursEvery.intervalType = 'hour';
                scheduleTestObject.dailyFrequency.occursEvery.intervalValue = 5;
                //calculate test case data
                let calculationResult = utools.calculateNextRun(scheduleTestObject);
                //manual calculation for validation
                let time = scheduleTestObject.dailyFrequency.start.split(':');
                let nextRunDateTime = new Date(utools.getDateTime().setHours(time[0], time[1], time[2], 0));
                while(nextRunDateTime < utools.getDateTime()) {
                    nextRunDateTime = utools.addDate(nextRunDateTime, 0, 0, 0, scheduleTestObject.dailyFrequency.occursEvery.intervalValue, 0, 0);
                }
                //log
                console.log('str: ', scheduleTestObject.startDateTime);
                console.log('end: ', scheduleTestObject.endDateTime);
                console.log('crn: ', utools.getDateTime());                
                console.log('int: ', scheduleTestObject.eachNDay);
                console.log('frc: ', scheduleTestObject.dailyFrequency.start, scheduleTestObject.dailyFrequency.occursEvery.intervalType, scheduleTestObject.dailyFrequency.occursEvery.intervalValue);
                console.log('clc: ', calculationResult);
                console.log('exp: ', nextRunDateTime);   
                //assertion
                assert.equalDate(calculationResult, nextRunDateTime);
                assert.equalTime(calculationResult, nextRunDateTime);
                done();
            });           
            it('success. run every 2 hours starting 09:18:36, each 12 days', function(done) {
                //test data preparation
                let scheduleTestObject = require('./test_data').dailyScheduleEveryOK;
                scheduleTestObject.startDateTime = utools.parseDateTime('2018-07-01T12:00:00.000Z');
                scheduleTestObject.eachNDay = 12;                
                scheduleTestObject.dailyFrequency.start = '09:18:36';
                scheduleTestObject.dailyFrequency.occursEvery.intervalType = 'hour';
                scheduleTestObject.dailyFrequency.occursEvery.intervalValue = 2;
                //calculate test case data
                let calculationResult = utools.calculateNextRun(scheduleTestObject);
                //manual calculation for validation
                let currentDate = new Date(utools.getDateTime().setHours(0, 0, 0, 0));
                let nextRunDateTime = new Date(scheduleTestObject.startDateTime);
                nextRunDateTime.setHours(0, 0, 0);
                //date
                while(nextRunDateTime < currentDate) {
                    nextRunDateTime = utools.addDate(nextRunDateTime, 0, 0, scheduleTestObject.eachNDay, 0, 0, 0);
                }
                //time
                let time = scheduleTestObject.dailyFrequency.start.split(':');
                nextRunDateTime = new Date(nextRunDateTime.setHours(time[0], time[1], time[2], 0));
                while(nextRunDateTime < utools.getDateTime()) {
                    nextRunDateTime = utools.addDate(nextRunDateTime, 0, 0, 0, scheduleTestObject.dailyFrequency.occursEvery.intervalValue, 0, 0);
                }
                //log
                console.log('str: ', scheduleTestObject.startDateTime);
                console.log('end: ', scheduleTestObject.endDateTime);
                console.log('crn: ', utools.getDateTime());                
                console.log('int: ', scheduleTestObject.eachNDay);
                console.log('frc: ', scheduleTestObject.dailyFrequency.start, scheduleTestObject.dailyFrequency.occursEvery.intervalType, scheduleTestObject.dailyFrequency.occursEvery.intervalValue);
                console.log('clc: ', calculationResult);
                console.log('exp: ', nextRunDateTime);   
                //assertion
                assert.equalDate(calculationResult, nextRunDateTime);
                assert.equalTime(calculationResult, nextRunDateTime);
                done();
            });    
            it('failure. run every 59 minutes starting 10:10:10, endDateTime restriction', function(done) {
                //test data preparation
                let scheduleTestObject = require('./test_data').dailyScheduleEveryOK;
                scheduleTestObject.startDateTime = utools.parseDateTime('2018-01-01T10:00:00.000Z');
                scheduleTestObject.eachNDay = 1;                
                scheduleTestObject.dailyFrequency.start = '10:10:10';
                scheduleTestObject.dailyFrequency.occursEvery.intervalType = 'minute';
                scheduleTestObject.dailyFrequency.occursEvery.intervalValue = 59;
                scheduleTestObject.endDateTime = utools.getDateTime();
                //calculate test case data
                let calculationResult = utools.calculateNextRun(scheduleTestObject);
                //log
                console.log('str: ', scheduleTestObject.startDateTime);
                console.log('end: ', scheduleTestObject.endDateTime);
                console.log('crn: ', utools.getDateTime());                
                console.log('int: ', scheduleTestObject.eachNDay);
                console.log('frc: ', scheduleTestObject.dailyFrequency.start, scheduleTestObject.dailyFrequency.occursEvery.intervalType, scheduleTestObject.dailyFrequency.occursEvery.intervalValue);
                console.log('clc: ', calculationResult);
                //assertion
                assert.isNull(calculationResult);
                done();
            });             
            //todo eachNDays>1        
        });
    });
});    
