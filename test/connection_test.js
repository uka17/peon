var assert  = require('chai').assert;
var request = require('request');
const config = require('../config/config');
var messageBox = require('../config/message_labels');
var id;
var testData = require('./test_data');
var testHelper = require('../app/tools/test_helper');
var helper = new testHelper(testData.connectionOK);

describe('connection', function() {
    describe('create', function() {
        let url = config.test_host + '/connections';
        helper.failedPostTest(url, 'name', 'string');
        helper.failedPostTest(url, 'host', 'string');
        helper.failedPostTest(url, 'port', 'integer');
        helper.failedPostTest(url, 'host', 'string');
        helper.failedPostTest(url, 'enabled', 'boolean');
        helper.failedPostTest(url, 'login', 'string');
        helper.failedPostTest(url, 'type', 'enum');
             
        it('OK', function(done) {       
            request.post({
                url: config.test_host + '/connections',  
                json: testData.connectionOK
            }, 
            function(error, response, body) {
                assert.equal(response.statusCode, 201);
                helper.compareObjects(body);
                assert.exists(body._id);
                id = body._id;
                done();
            });
        });

        it('create by id. error 405', function(done) {
            request.post({
                url: config.test_host + '/connections/' + id,  
                json: testData.connectionOK
            }, 
            function(error, response, body) {
                assert.equal(response.statusCode, 405);
                done();
            });
        });
    });

    describe('list, get and count', function() {
        it('list. OK', function(done) {
            request.get({
                url: config.test_host + '/connections', 
                json: true
            },
            function(error, response, body) {
                assert.equal(response.statusCode, 200);
                assert.isAbove(body.length, 0);
                done();
            });
        });
        
        it('get. OK', function(done) {    
            request.get({
                url: config.test_host + '/connections/' + id, 
                json: true
            },
            function(error, response, body) {
                helper.compareObjects(body);
                done();
            });
        });

        it('count. OK', function(done) {            
            request.get({
                url: config.test_host + '/connections/count',
                json: true 
            },
            function(error, response, body) {
                assert.equal(response.statusCode, 200);
                assert.isAbove(body[messageBox.common.count], 0);
                done();
            });
        });
    });

    describe('update and delete', function() {
        let nConnection = JSON.parse(JSON.stringify(testData.connectionOK));
        nConnection.name = 'new_name';
        it('update. OK', function(done) {    
            request.patch({
                url: config.test_host + '/connections/' + id, 
                json: nConnection
            },
            function(error, response, body) {
                assert.equal(response.statusCode, 200);
                assert.equal(body[messageBox.common.updated], 1);
                request.get({
                    url: config.test_host + '/connections/' + id, 
                    json: true
                },
                function(error, response, body) {
                    assert.equal(response.statusCode, 200);
                    assert.equal(body.name, 'new_name');
                    done();
                });
            });
        });

        it('delete. OK', function(done) {    
            request.delete({
                url: config.test_host + '/connections/' + id,
                json: true
            },
            function(error, response, body) {
                assert.equal(response.statusCode, 200);
                assert.equal(body[messageBox.common.deleted], 1);
                done();
            });
        });
    });    
}); 