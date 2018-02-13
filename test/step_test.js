var assert  = require('chai').assert;
var request = require('request');
const config = require('../config/config');
var jobId;
var stepId;

describe('Step', function() {
    it('Create job', function(done) {
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

    it('Create step', function(done) {
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

    it('Steps count', function(done) {
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

    it('Get step list', function(done) {
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

    it('Get step by id', function(done) {
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

    it('Change step by id', function(done) {
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

    it('Delete step', function(done) {    
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
                assert.equal(response.statusCode, 404);
                done();
            });
        });
    });

    it('Delete job', function(done) {    
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