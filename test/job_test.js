var assert  = require('chai').assert;
var request = require('request');
const config = require('../config/config');
var id;

describe('Job', function() {
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
            id = body._id;
            done();
        });
    });

    it('Create job by id (405)', function(done) {
        request.post({
            url: config.test_host + '/jobs/' + id,  
            json: {"name": "job", "description": "job description", "enabled": true}
        }, 
        function(error, response, body) {
            assert.equal(response.statusCode, 405);
            done();
        });
    });

    it('Jobs list', function(done) {
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

    it('Jobs count', function(done) {
        request.get({
            url: config.test_host + '/jobs/count',
            json: true 
        },
        function(error, response, body) {
            assert.equal(response.statusCode, 200);
            assert.isAbove(body.count, 1);
            done();
        });
    });

    it('Get job', function(done) {    
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

    it('Update job', function(done) {    
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

    it('Delete job', function(done) {    
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