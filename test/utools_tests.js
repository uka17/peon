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
            assert.equal(utools.getTimefromDateTime(dateTime), '05:03:04'); //UTC+3
            done();
        });           
        it('getTimefromDateTime. date provided and no leading zeroes', function(done) {
            let dateTime = utools.parseDateTime('2018-01-31T12:13:14.071Z');
            assert.equal(utools.getTimefromDateTime(dateTime), '15:13:14'); //UTC+3
            done();
        });                   
        it('getTimefromDateTime. date is not provided', function(done) {
            assert.equal(utools.getTimefromDateTime(), (new Date()).toTimeString().substr(0,8)); //UTC+3
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
            assert.equal(initial.toDateString(), expected.toDateString());
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
            it('success', function(done) {
                let scheduleTestObject = require('./test_data').dailyScheduleOnceOK;
                scheduleTestObject.startDateTime = utools.getDateTime();
                scheduleTestObject.eachNDay = 1;
                let nextHourDateTime = utools.addDate(utools.getDateTime(), 0, 0, 0, 0, 0, 5); //test will fail between 23:55:00 and 00:00:00
                scheduleTestObject.dailyFrequency.occursOnceAt = utools.getTimefromDateTime(nextHourDateTime);
                assert.equalDate(utools.calculateNextRun(scheduleTestObject), nextHourDateTime);
                assert.equalTime(utools.calculateNextRun(scheduleTestObject), nextHourDateTime);
                done();
            });      
        });

    });
});    
