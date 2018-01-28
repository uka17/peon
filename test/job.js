var assert  = require('chai').assert;
var request = require('request');
var id;

it('Create job', function(done) {
    request.post({
        url: 'http://localhost:8080/jobs',  
        json: {"name": "job", "description": "job description", "enabled": true}
    }, 
    function(error, response, body) {
        assert.equal(response.statusCode, 201);
        assert.equal(body.name, "job");
        assert.equal(body.description, "job description");
        assert.equal(body.enabled, true);
        assert.exists(body._id);
        id = body._id;
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

