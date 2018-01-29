var assert  = require('chai').assert;
var request = require('request');
var id;
/*
const MongoClient = require('mongodb').MongoClient;
const db = require('../config/db');
const port = 8080;
MongoClient.connect(db.url, (err, client) => {
    client.db('peon').collection('job').insert({name: "start"});         
  })
*/
describe('Job', function() {
    it('Create job', function(done) {
        request.post({
            url: 'http://localhost:8080/jobs',  
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
            url: 'http://localhost:8080/jobs/' + id,  
            json: {"name": "job", "description": "job description", "enabled": true}
        }, 
        function(error, response, body) {
            assert.equal(response.statusCode, 405);
            done();
        });
    });

    it('Job list', function(done) {
        request.get({
            url: 'http://localhost:8080/jobs', 
        },
        function(error, response, body) {
            assert.equal(response.statusCode, 200);
            assert.isAbove(body.length, 0);
            done();
        });
    });

    it('Get job', function(done) {    
        request.get({
            url: 'http://localhost:8080/jobs/' + id, 
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
        request.put({
            url: 'http://localhost:8080/jobs/' + id, 
            json: {"name": "job_changed", "description": "description_changed", "enabled": false}
        },
        function(error, response, body) {
            assert.equal(response.statusCode, 200);
            assert.equal(body.itemsUpdated, 1);
            request.get({
                url: 'http://localhost:8080/jobs/' + id, 
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
            url: 'http://localhost:8080/jobs/' + id,
            json: true
        },
        function(error, response, body) {
            assert.equal(response.statusCode, 200);
            assert.equal(body.itemsDeleted, 1);
            done();
        });
    });
});    