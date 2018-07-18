var assert  = require('chai').assert;
var request = require('request');
const config = require('../config/config');
var messageBox = require('../config/message_labels');
var id;
var testData = require('./test_data');

describe('connection', function() {
    describe('create', function() {
        it('incorrect "name"', function(done) {
            let nConnection = JSON.parse(JSON.stringify(testData.connectionOK));            
            nConnection.name = true;
            request.post({
                url: config.test_host + '/connections',  
                json: nConnection
            }, 
            function(error, response, body) {
                assert.equal(response.statusCode, 400);
                done();
            });
        });
        it('incorrect "host"', function(done) {
            let nConnection = JSON.parse(JSON.stringify(testData.connectionOK));            
            nConnection.host = true;
            request.post({
                url: config.test_host + '/connections',  
                json: nConnection
            }, 
            function(error, response, body) {
                assert.equal(response.statusCode, 400);
                done();
            });
        });
        it('incorrect "port"', function(done) {
            let nConnection = JSON.parse(JSON.stringify(testData.connectionOK));            
            nConnection.port = true;
            request.post({
                url: config.test_host + '/connections',  
                json: nConnection
            }, 
            function(error, response, body) {
                assert.equal(response.statusCode, 400);
                done();
            });
        });
        it('incorrect "enabled"', function(done) {
            let nConnection = JSON.parse(JSON.stringify(testData.connectionOK));            
            nConnection.enabled = 'aaa';
            request.post({
                url: config.test_host + '/connections',  
                json: nConnection
            }, 
            function(error, response, body) {
                assert.equal(response.statusCode, 400);
                done();
            });
        });
        it('incorrect "login"', function(done) {
            let nConnection = JSON.parse(JSON.stringify(testData.connectionOK));            
            nConnection.login = true;
            request.post({
                url: config.test_host + '/connections',  
                json: nConnection
            }, 
            function(error, response, body) {
                assert.equal(response.statusCode, 400);
                done();
            });
        });
        it('incorrect "password"', function(done) {
            let nConnection = JSON.parse(JSON.stringify(testData.connectionOK));            
            nConnection.password = true;
            request.post({
                url: config.test_host + '/connections',  
                json: nConnection
            }, 
            function(error, response, body) {
                assert.equal(response.statusCode, 400);
                done();
            });
        });             
        it('incorrect "type"', function(done) {
            let nConnection = JSON.parse(JSON.stringify(testData.connectionOK));            
            nConnection.type = 'true';
            request.post({
                url: config.test_host + '/connections',  
                json: nConnection
            }, 
            function(error, response, body) {
                assert.equal(response.statusCode, 400);
                done();
            });
        });                        


        it('OK', function(done) {
            let nConnection = JSON.parse(JSON.stringify(testData.connectionOK));            
            request.post({
                url: config.test_host + '/connections',  
                json: nConnection
            }, 
            function(error, response, body) {
                assert.equal(response.statusCode, 201);
                assert.equal(body.name, nConnection.name);
                assert.equal(body.host, nConnection.host);
                assert.equal(body.port, nConnection.port);
                assert.equal(body.login, nConnection.login);
                assert.equal(body.password, nConnection.password);
                assert.equal(body.type, nConnection.type);
                assert.equal(body.enabled, nConnection.enabled);
                assert.exists(body._id);
                id = body._id;
                done();
            });
        });

        it('create by id. error 405', function(done) {
            let nConnection = JSON.parse(JSON.stringify(testData.connectionOK));
            request.post({
                url: config.test_host + '/connections/' + id,  
                json: nConnection
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
            let nConnection = JSON.parse(JSON.stringify(testData.connectionOK));
            request.get({
                url: config.test_host + '/connections/' + id, 
            },
            function(error, response, body) {
                var parsedBody = JSON.parse(body);
                assert.equal(response.statusCode, 200);
                assert.equal(parsedBody.name, nConnection.name);
                assert.equal(parsedBody.host, nConnection.host);
                assert.equal(parsedBody.port, nConnection.port);
                assert.equal(parsedBody.login, nConnection.login);
                assert.equal(parsedBody.password, nConnection.password);
                assert.equal(parsedBody.type, nConnection.type);
                assert.equal(parsedBody.enabled, nConnection.enabled);
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
                },
                function(error, response, body) {
                    assert.equal(response.statusCode, 200);
                    var parsedBody = JSON.parse(body);
                    assert.equal(parsedBody.name, 'new_name');
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