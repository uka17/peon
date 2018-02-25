var assert  = require('chai').assert;
var request = require('request');
const config = require('../config/config');
var id;

describe('Job', function() {
    it('Create job. Error (incorrect "name")', function(done) {
        request.post({
            url: config.test_host + '/jobs',  
            json: {"name": true, "description": "job description", "enabled": true}
        }, 
        function(error, response, body) {
            assert.equal(response.statusCode, 500);
            done();
        });
    });

    it('Create job. Error (incorrect "description")', function(done) {
        request.post({
            url: config.test_host + '/jobs',  
            json: {"name": "name", "description": true, "enabled": true}
        }, 
        function(error, response, body) {
            assert.equal(response.statusCode, 500);
            done();
        });
    });

    it('Create job. Error (incorrect "enabled")', function(done) {
        request.post({
            url: config.test_host + '/jobs',  
            json: {"name": "name", "description": "job description", "enabled": 1}
        }, 
        function(error, response, body) {
            assert.equal(response.statusCode, 500);
            done();
        });
    });

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
            id = body._id;
            done();
        });
    });

    it('Create job by id. Error (405)', function(done) {
        request.post({
            url: config.test_host + '/jobs/' + id,  
            json: {"name": "job", "description": "job description", "enabled": true}
        }, 
        function(error, response, body) {
            assert.equal(response.statusCode, 405);
            done();
        });
    });

    it('Jobs list. Success', function(done) {
        request.get({
            url: config.test_host + '/jobs', 
            json: true
        },
        function(error, response, body) {
            assert.equal(response.statusCode, 200);
            assert.isAbove(body.length, 0);
            done();
        });
    });

    it('Jobs count. Success', function(done) {
        request.get({
            url: config.test_host + '/jobs/count',
            json: true 
        },
        function(error, response, body) {
            assert.equal(response.statusCode, 200);
            assert.isAbove(body.count, 0);
            done();
        });
    });

    it('Get job. Success', function(done) {    
        request.get({
            url: config.test_host + '/jobs/' + id, 
        },
        function(error, response, body) {
            assert.equal(response.statusCode, 200);
            var parsedBody = JSON.parse(body);
            assert.equal(parsedBody.name, 'job');
            assert.equal(parsedBody.description, 'job description');
            assert.equal(parsedBody.enabled, true);
            done();
        });
    });

    it('Update job. Success', function(done) {    
        request.patch({
            url: config.test_host + '/jobs/' + id, 
            json: {"name": "job_changed", "description": "description_changed", "enabled": false}
        },
        function(error, response, body) {
            assert.equal(response.statusCode, 200);
            assert.equal(body.itemsUpdated, 1);
            request.get({
                url: config.test_host + '/jobs/' + id, 
            },
            function(error, response, body) {
                assert.equal(response.statusCode, 200);
                var parsedBody = JSON.parse(body);
                assert.equal(parsedBody.name, 'job_changed');
                assert.equal(parsedBody.description, 'description_changed');
                assert.equal(parsedBody.enabled, false);
                done();
            });
        });
    });

    it('Delete job. Success', function(done) {    
        request.delete({
            url: config.test_host + '/jobs/' + id,
            json: true
        },
        function(error, response, body) {
            assert.equal(response.statusCode, 200);
            assert.equal(body.itemsDeleted, 1);
            done();
        });
    });
});    