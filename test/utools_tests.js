//utools unit tests
var assert  = require('chai').assert;

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
        it('getTimestamp ', function(done) {
            assert.equal(utools.getTimestamp().toString(), new Date());
            done();
        });   
        it('renameProperty', function(done) {
            let expected = {new_name: 'obj_name', val: 1};
            let initial = {name: 'obj_name', val: 1};
            assert.equal(utools.renameProperty(initial, 'name', 'new_name').toString(), expected.toString());
            done();
        });  
        it('addDate 1+', function(done) {
            let expected = new Date(Date.parse('2018-01-31T02:02:02.071Z'));            
            let initial = new Date(Date.parse('2018-01-31T01:01:01.071Z'));
            initial = utools.addDate(initial, 0, 0, 0, 1, 1, 1);
            assert.equal(initial.toDateString(), expected.toDateString());
            done();
        });         
        it('addDate 2+', function(done) {
            let initial = new Date(Date.parse('2018-02-28T23:00:00.000Z'));            
            let expected = new Date(Date.parse('2018-03-01T01:00:00.000Z'));
            initial = utools.addDate(initial, 0, 0, 0, 2, 0, 0);
            assert.equal(initial.toDateString(), expected.toDateString());
            done();
        });            
        it('addDate 3+', function(done) {
            let initial = new Date(Date.parse('2018-06-10T02:02:02.071Z'));            
            let expected = new Date(Date.parse('2019-06-10T02:02:02.071Z'));
            initial = utools.addDate(initial, 1, 0, 0, 0, 0, 0);
            assert.equal(initial.toDateString(), expected.toDateString());
            done();
        });             
        it('addDate 4-', function(done) {
            let expected = new Date(Date.parse('2018-01-31T01:01:01.000Z'));            
            let initial = new Date(Date.parse('2018-01-31T02:02:02.000Z'));
            initial = utools.addDate(initial, 0, 0, 0, -1, -1, -1);
            assert.equal(initial.toDateString(), expected.toDateString());
            done();
        });         
        it('addDate 5-', function(done) {
            let initial = new Date(Date.parse('2018-05-01T01:00:00.000Z'));            
            let expected = new Date(Date.parse('2018-04-30T23:00:00.000Z'));
            initial = utools.addDate(initial, 0, 0, 0, -2, 0, 0);
            assert.equal(initial.toDateString(), expected.toDateString());
            done();
        });            
        it('addDate 6-', function(done) {
            let initial = new Date(Date.parse('2019-06-10T02:02:02.071Z'));            
            let expected = new Date(Date.parse('2018-06-10T02:02:02.071Z'));
            initial = utools.addDate(initial, -1, 0, 0, 0, 0, 0);
            assert.equal(initial.toDateString(), expected.toDateString());
            done();
        });                 
    });

    describe('calculateNextRun', function() {
        it('getTimestamp ', function(done) {
            assert.equal(utools.getTimestamp().toString(), new Date());
            done();
        }); 
    });
});    
