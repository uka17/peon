var assert  = require('chai').assert;
const config = require('../config/config');
var messageBox = require('../config/message_labels');
var jobId;
var testData = require('./test_data');
var testHelper = require('./test_helper');
var utools = require('../app/tools/utools');
const request = require("supertest");
var ver = '/v1.0';
var job_routes = require('../app/routes/job_routes');
var jobTestHelper = new testHelper(testData.jobOK);
 
describe('job', function() {
    describe('create', function() {
        it('incorrect "description"', () => {
            return utools.expressMongoInstancePromise(job_routes, config.mongodb_url).then(response => {                               
                let nJob = JSON.parse(JSON.stringify(testData.jobOK));
                nJob.description = true;
                request(response.app)
                .post(ver + '/jobs')            
                .send(nJob)
                .set('Accept', 'application/json')
                .end(function(err, res) { 
                    assert.equal(res.status, 400);
                    assert.include(res.body.requestValidationErrors, 'description');
                    response.dbclient.close()
                });                    
            }); 
        });   
        it('successful POST', () => {
            return utools.expressMongoInstancePromise(job_routes, config.mongodb_url).then(response => {                               
                request(response.app)
                    .post(ver + '/jobs')            
                    .send(testData.jobOK)
                    .set('Accept', 'application/json')
                    .end(function(err, res) { 
                        assert.equal(res.status, 201);
                        assert.equal(res.body.name, testData.jobOK.name);
                        jobId = res.body._id;
                        response.dbclient.close()
                    });                    
            }); 
        });  
        it('failed POST (405)', () => {
            return utools.expressMongoInstancePromise(job_routes, config.mongodb_url).then(response => {                               
                request(response.app)
                    .post(ver + '/jobs/' + jobId)            
                    .send(testData.jobOK)
                    .set('Accept', 'application/json')
                    .end(function(err, res) { 
                        assert.equal(res.status, 405);
                        response.dbclient.close()
                    });                    
            }); 
        });          
        it('successful count', () => {
            return utools.expressMongoInstancePromise(job_routes, config.mongodb_url).then(response => {                               
                request(response.app)
                    .get(ver + '/jobs/count')            
                    .set('Accept', 'application/json')
                    .end(function(err, res) { 
                        assert.equal(res.status, 200);
                        assert.isAbove(res.body.count, 0);
                        response.dbclient.close()
                    });                    
            }); 
        });  
        it('successful get', () => {
            return utools.expressMongoInstancePromise(job_routes, config.mongodb_url).then(response => {                               
                request(response.app)
                    .get(ver + '/jobs/' + jobId)            
                    .set('Accept', 'application/json')
                    .end(function(err, res) { 
                        assert.equal(res.status, 200);
                        jobTestHelper.compareObjects(res.body);
                        response.dbclient.close()
                    });                    
            }); 
        });     
        it('successful list', () => {
            return utools.expressMongoInstancePromise(job_routes, config.mongodb_url).then(response => {                               
                request(response.app)
                    .get(ver + '/jobs')            
                    .set('Accept', 'application/json')
                    .end(function(err, res) { 
                        assert.equal(res.statusCode, 200);
                        assert.isAbove(res.body.length, 0);
                        response.dbclient.close()
                    });                    
            }); 
        });     
        it('successful patch', () => {
            return utools.expressMongoInstancePromise(job_routes, config.mongodb_url).then(response => {                               
                let nJob = JSON.parse(JSON.stringify(testData.jobOK));
                nJob.description = 'new_description';
                request(response.app)
                    .patch(ver + '/jobs/' + jobId)            
                    .send(testData.jobOK)
                    .set('Accept', 'application/json')
                    .end(function(err, res) { 
                        assert.equal(res.statusCode, 200);
                        assert.equal(res.body[messageBox.common.updated], 1)
                        response.dbclient.close()
                    });                    
            }); 
        });             
        it('successful delete', () => {
            return utools.expressMongoInstancePromise(job_routes, config.mongodb_url).then(response => {                               
                request(response.app)
                    .delete(ver + '/jobs/' + jobId)            
                    .set('Accept', 'application/json')
                    .end(function(err, res) { 
                        assert.equal(res.statusCode, 200);
                        assert.equal(res.body[messageBox.common.deleted], 1)
                        response.dbclient.close()
                    });                    
            }); 
        });                                    
    });
});


