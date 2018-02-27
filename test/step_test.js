var mongo = require('mongodb');
var assert  = require('chai').assert;
var request = require('request');
var messageBox = require('../config/message_box');
const config = require('../config/config');
var jobId;
var stepId;
var fakeId = new mongo.ObjectID('0a9296f2496698264c23e180');

describe('Step', function() {
    it('Create job. Success', function(done) {
        request.post({
            url: config.test_host + '/jobs',  
            json: {"name": "job", "description": "job description", "enabled": true}
        }, 
        function(error, response, body) {
            assert.equal(response.statusCode, 201);
            assert.equal(body.name, 'job');
            assert.equal(body.description, 'job description');
            assert.equal(body.enabled, true);
            assert.exists(body._id);
            jobId = body._id;
            done();
        });
    });

    it('Get step by id. Error (no steps for this fakeJobId)', function(done) {
        request.get({
            url: config.test_host + '/jobs/' + jobId+ '/steps/' + fakeId,
            json: true
        }, 
        function(error, response, body) {
            assert.equal(response.statusCode, 500);
            assert.include(response.body.error, messageBox.noStepForJob);
            done();
        });
    });

    it('Get step by id. Error (no steps for this jobId)', function(done) {
        request.get({
            url: config.test_host + '/jobs/' + jobId+ '/steps',
            json: true
        }, 
        function(error, response, body) {
            assert.equal(response.statusCode, 500);
            assert.include(response.body.error, messageBox.noStepForJob);
            done();
        });
    });

    it('Create step. Error (incorrect "name")', function(done) {
        request.post({
            url: config.test_host + '/jobs/' + jobId + '/steps',  
            json: {"name": 1, "connection": "step_connection", "enabled": true, "database": "step_db", "command": "step_command"}
        }, 
        function(error, response, body) {
            assert.equal(response.statusCode, 500);          
            done();
        });
    });

    it('Create step. Error (incorrect "connection")', function(done) {
        request.post({
            url: config.test_host + '/jobs/' + jobId + '/steps',  
            json: {"name": "name", "connection": 1, "enabled": true, "database": "step_db", "command": "step_command"}
        }, 
        function(error, response, body) {
            assert.equal(response.statusCode, 500);          
            done();
        });
    });

    it('Create step. Error (incorrect "enabled")', function(done) {
        request.post({
            url: config.test_host + '/jobs/' + jobId + '/steps',  
            json: {"name": "name", "connection": "step_connection", "enabled": 5, "database": "step_db", "command": "step_command"}
        }, 
        function(error, response, body) {
            assert.equal(response.statusCode, 500);          
            done();
        });
    });

    it('Create step. Error (incorrect "database")', function(done) {
        request.post({
            url: config.test_host + '/jobs/' + jobId + '/steps',  
            json: {"name": "name", "connection": "step_connection", "enabled": true, "database": true, "command": "step_command"}
        }, 
        function(error, response, body) {
            assert.equal(response.statusCode, 500);          
            done();
        });
    });

    it('Create step. Error (incorrect "command")', function(done) {
        request.post({
            url: config.test_host + '/jobs/' + jobId + '/steps',  
            json: {"name": "name", "connection": "step_connection", "enabled": true, "database": "step_db", "command": false}
        }, 
        function(error, response, body) {
            assert.equal(response.statusCode, 500);          
            done();
        });
    });

    it('Steps count. Success (count=0)', function(done) {
        request.get({
            url: config.test_host + '/jobs/' + jobId + '/steps/count',
            json: true
        }, 
        function(error, response, body) {
            assert.equal(response.statusCode, 200);
            assert.equal(body.count, 0);            
            done();
        });
    });

    it('Create step. Success', function(done) {
        request.post({
            url: config.test_host + '/jobs/' + jobId + '/steps',  
            json: {"name": "step_name", "connection": "step_connection", "enabled": true, "database": "step_db", "command": "step_command"}
        }, 
        function(error, response, body) {
            assert.equal(response.statusCode, 201);
            assert.equal(body.itemsUpdated, 1);            
            done();
        });
    });

    it('Steps count. Success (count=1)', function(done) {
        request.get({
            url: config.test_host + '/jobs/' + jobId + '/steps/count',
            json: true
        }, 
        function(error, response, body) {
            assert.equal(response.statusCode, 200);
            assert.equal(body.count, 1);            
            done();
        });
    });

    it('Get step list. Success', function(done) {
        request.get({
            url: config.test_host + '/jobs/' + jobId + '/steps',
            json: true
        }, 
        function(error, response, body) {
            assert.equal(response.statusCode, 200);
            assert.equal(body.length, 1);
            assert.equal(body[0].name, 'step_name');
            stepId = body[0]._id;
            done();
        });
    });

    it('Get step by id. Success', function(done) {
        request.get({
            url: config.test_host + '/jobs/' + jobId + '/steps/' + stepId,
            json: true
        }, 
        function(error, response, body) {
            assert.equal(response.statusCode, 200);
            assert.equal(body.name, 'step_name');
            assert.equal(body.connection, 'step_connection');
            assert.equal(body.enabled, true);
            assert.equal(body.database, 'step_db');
            assert.equal(body.command, 'step_command');
            stepId = body._id;
            done();
        });
    });

    it('Get step by id. Error (incorrect stepId)', function(done) {
        request.get({
            url: config.test_host + '/jobs/' + jobId + '/steps/' + fakeId,
            json: true
        }, 
        function(error, response, body) {
            assert.equal(response.statusCode, 500);
            assert.include(response.body.error, messageBox.noStepForJobAndStep);
            done();
        });
    });

    it('Get step by id. Error (incorrect jobId)', function(done) {
        request.get({
            url: config.test_host + '/jobs/' + fakeId + '/steps/' + stepId,
            json: true
        }, 
        function(error, response, body) {
            assert.equal(response.statusCode, 500);
            assert.include(response.body.error, messageBox.jobNotFound);
            done();
        });
    });

    it('Change step by id. Success', function(done) {
        request.patch({
            url: config.test_host + '/jobs/' + jobId + '/steps/' + stepId,
            json: {"name": "step_name1", "connection": "step_connection1", "enabled": true, "database": "step_db1", "command": "step_command"}
        }, 
        function(error, response, body) {
            assert.equal(response.statusCode, 200);
            assert.equal(body.itemsUpdated, 1);  
            request.get({
                url: config.test_host + '/jobs/' + jobId + '/steps/' + stepId,
                json: true
            }, 
            function(error, response, body) {
                assert.equal(response.statusCode, 200);
                assert.equal(body.name, 'step_name1');
                assert.equal(body.connection, 'step_connection1');
                assert.equal(body.enabled, true);
                assert.equal(body.database, 'step_db1');
                assert.equal(body.command, 'step_command');
                stepId = body._id;
                done();
            });
        });
    });    

    it('Delete step. Success', function(done) {    
        request.delete({
            url: config.test_host + '/jobs/' + jobId + '/steps/' + stepId,
            json: true
        },
        function(error, response, body) {
            assert.equal(response.statusCode, 200);
            assert.equal(body.itemsDeleted, 1);
            request.get({
                url: config.test_host + '/jobs/' + jobId + '/steps/' + stepId,
                json: true
            }, 
            function(error, response, body) {
                assert.equal(response.statusCode, 500);
                done();
            });
        });
    });

    it('Delete job. Success', function(done) {    
        request.delete({
            url: config.test_host + '/jobs/' + jobId,
            json: true
        },
        function(error, response, body) {
            assert.equal(response.statusCode, 200);
            assert.equal(body.itemsDeleted, 1);
            done();
        });
    });
});    