var assert  = require('chai').assert;
const config = require('../config/config');
var messageBox = require('../config/message_labels');
var connectionId;
var testData = require('./test_data');
var testHelper = require('./test_helper');
var utools = require('../app/tools/utools');
const request = require("supertest");
var ver = '/v1.0';
var connection_routes = require('../app/routes/connection_routes');
var connectionTestHelper = new testHelper(testData.connectionOK);

describe('connection', function() {
    describe('create', function() {
        it('incorrect "name"', () => {
            return utools.expressMongoInstancePromise(connection_routes, config.mongodb_url).then(response => {                               
                let nConnection = JSON.parse(JSON.stringify(testData.connectionOK));
                nConnection.name = true;
                request(response.app)
                .post(ver + '/connections')            
                .send(nConnection)
                .set('Accept', 'application/json')
                .end(function(err, res) { 
                    assert.equal(res.status, 400);
                    assert.include(res.body.requestValidationErrors, 'name');
                    response.dbclient.close()
                });                    
            }); 
        });   
        it('successful POST', () => {
            return utools.expressMongoInstancePromise(connection_routes, config.mongodb_url).then(response => {                               
                request(response.app)
                    .post(ver + '/connections')            
                    .send(testData.connectionOK)
                    .set('Accept', 'application/json')
                    .end(function(err, res) { 
                        assert.equal(res.status, 201);
                        assert.equal(res.body.name, testData.connectionOK.name);
                        connectionId = res.body._id;
                        response.dbclient.close()
                    });                    
            }); 
        });               
        
    });
}); 