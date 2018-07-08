var mongo = require('mongodb');
var assert  = require('chai').assert;
var request = require('request');
var messageBox = require('../config/message_labels');
const config = require('../config/config');
var jobId;
var stepId;
var fakeId = new mongo.ObjectID('0a9296f2496698264c23e180');

describe('step', function() {
    it('create job. Success', function(done) {
        request.post({
            url: config.test_host + '/jobs',  
            json: {"name": "testJob", "description": "job description", "enabled": true}
        }, 
        function(error, response, body) {
            assert.equal(response.statusCode, 201);
            assert.equal(body.name, 'testJob');
            assert.equal(body.description, 'job description');
            assert.equal(body.enabled, true);
            assert.exists(body._id);
            jobId = body._id;
            done();
        });
    });

    it('get step by id. Error (no steps for this fakeJobId)', function(done) {
        request.get({
            url: config.test_host + '/jobs/' + jobId+ '/steps/' + fakeId,
            json: true
        }, 
        function(error, response, body) {
            assert.equal(response.statusCode, 404);
            assert.include(response.body.error, messageBox.step.noStepForJob);
            done();
        });
    });

    it('get step by id. Error (no steps for this jobId)', function(done) {
        request.get({
            url: config.test_host + '/jobs/' + jobId+ '/steps',
            json: true
        }, 
        function(error, response, body) {
            assert.equal(response.statusCode, 404);
            assert.include(response.body.error, messageBox.step.noStepForJob);
            done();
        });
    });

    it('create step. Error (incorrect "name")', function(done) {
        request.post({
            url: config.test_host + '/jobs/' + jobId + '/steps',  
            json: {"name": 1, "connection": "step_connection", "enabled": true, "database": "step_db", "command": "step_command"}
        }, 
        function(error, response, body) {
            assert.equal(response.statusCode, 500);          
            done();
        });
    });

    it('create step. Error (incorrect "connection")', function(done) {
        request.post({
            url: config.test_host + '/jobs/' + jobId + '/steps',  
            json: {"name": "name", "connection": 1, "enabled": true, "database": "step_db", "command": "step_command"}
        }, 
        function(error, response, body) {
            assert.equal(response.statusCode, 500);          
            done();
        });
    });

    it('create step. Error (incorrect "enabled")', function(done) {
        request.post({
            url: config.test_host + '/jobs/' + jobId + '/steps',  
            json: {"name": "name", "connection": "step_connection", "enabled": 5, "database": "step_db", "command": "step_command"}
        }, 
        function(error, response, body) {
            assert.equal(response.statusCode, 500);          
            done();
        });
    });

    it('create step. Error (incorrect "database")', function(done) {
        request.post({
            url: config.test_host + '/jobs/' + jobId + '/steps',  
            json: {"name": "name", "connection": "step_connection", "enabled": true, "database": true, "command": "step_command"}
        }, 
        function(error, response, body) {
            assert.equal(response.statusCode, 500);          
            done();
        });
    });

    it('create step. Error (incorrect "command")', function(done) {
        request.post({
            url: config.test_host + '/jobs/' + jobId + '/steps',  
            json: {"name": "name", "connection": "step_connection", "enabled": true, "database": "step_db", "command": false}
        }, 
        function(error, response, body) {
            assert.equal(response.statusCode, 500);          
            done();
        });
    });

    it('create step. Error (onSucceed.gotoStep=-1)', function(done) {
        request.post({
            url: config.test_host + '/jobs/' + jobId + '/steps',  
            json: {"name": "step_name", "connection": "step_connection", "enabled": true, "database": "step_db", "command": "step_command",
                "onSucceed": {'gotoStep': -1}
            }
        }, 
        function(error, response, body) {
            assert.equal(response.statusCode, 500);          
            done();
        });
    });

    it('create step. Error (onSucceed.gotoStep without value)', function(done) {
        request.post({
            url: config.test_host + '/jobs/' + jobId + '/steps',  
            json: {"name": "step_name", "connection": "step_connection", "enabled": true, "database": "step_db", "command": "step_command",
                "onSucceed": 'gotoStep'
            }
        }, 
        function(error, response, body) {
            assert.equal(response.statusCode, 500);          
            done();
        });
    });

    it('create step. Error (onSucceed incorrect value)', function(done) {
        request.post({
            url: config.test_host + '/jobs/' + jobId + '/steps',  
            json: {"name": "step_name", "connection": "step_connection", "enabled": true, "database": "step_db", "command": "step_command",
                "onSucceed": 'incorrect'
            }
        }, 
        function(error, response, body) {
            assert.equal(response.statusCode, 500);          
            done();
        });
    });

    it('steps count. Success (count=0)', function(done) {
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

    it('create step. Success', function(done) {
        request.post({
            url: config.test_host + '/jobs/' + jobId + '/steps',  
            json: {"name": "step_name", "connection": {}, "enabled": true, "database": "step_db", "command": "step_command",
                "onSucceed": {"gotoStep": 2}
            }
        }, 
        function(error, response, body) {
            assert.equal(response.statusCode, 201);
            assert.equal(body[messageBox.common.updated], 1);            
            done();
        });
    });

    it('steps count. Success (count=1)', function(done) {
        request.get({
            url: config.test_host + '/jobs/' + jobId + '/steps/count',
            json: true
        }, 
        function(error, response, body) {
            assert.equal(response.statusCode, 200);
            assert.equal(body[messageBox.common.count], 1);            
            done();
        });
    });

    it('get step list. Success', function(done) {
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

    it('get step by id. Success', function(done) {
        request.get({
            url: config.test_host + '/jobs/' + jobId + '/steps/' + stepId,
            json: true
        }, 
        function(error, response, body) {
            assert.equal(response.statusCode, 200);
            assert.equal(body.name, 'step_name');
            assert.deepEqual(body.connection, {});
            assert.equal(body.enabled, true);
            assert.equal(body.database, 'step_db');
            assert.equal(body.command, 'step_command');
            stepId = body._id;
            done();
        });
    });

    it('get step by id. Error (incorrect stepId)', function(done) {
        request.get({
            url: config.test_host + '/jobs/' + jobId + '/steps/' + fakeId,
            json: true
        }, 
        function(error, response, body) {
            assert.equal(response.statusCode, 404);
            assert.include(response.body.error, messageBox.step.noStepForJobAndStep);
            done();
        });
    });

    it('get step by id. Error (incorrect jobId)', function(done) {
        request.get({
            url: config.test_host + '/jobs/' + fakeId + '/steps/' + stepId,
            json: true
        }, 
        function(error, response, body) {
            assert.equal(response.statusCode, 404);
            assert.include(response.body.error, messageBox.job.jobNotFound);
            done();
        });
    });

    it('change step by id. Success', function(done) {
        request.patch({
            url: config.test_host + '/jobs/' + jobId + '/steps/' + stepId,
            json: {"name": "step_name1", "connection": {}, "enabled": true, "database": "step_db1", "command": "step_command"}
        }, 
        function(error, response, body) {
            assert.equal(response.statusCode, 200);
            assert.equal(body[messageBox.common.updated], 1);  
            request.get({
                url: config.test_host + '/jobs/' + jobId + '/steps/' + stepId,
                json: true
            }, 
            function(error, response, body) {
                assert.equal(response.statusCode, 200);
                assert.equal(body.name, 'step_name1');
                assert.deepEqual(body.connection, {});
                assert.equal(body.enabled, true);
                assert.equal(body.database, 'step_db1');
                assert.equal(body.command, 'step_command');
                stepId = body._id;
                done();
            });
        });
    });    

    it('delete step. Success', function(done) {    
        request.delete({
            url: config.test_host + '/jobs/' + jobId + '/steps/' + stepId,
            json: true
        },
        function(error, response, body) {
            assert.equal(response.statusCode, 200);
            assert.equal(body[messageBox.common.deleted], 1);
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

    it('delete job. Success', function(done) {    
        request.delete({
            url: config.test_host + '/jobs/' + jobId,
            json: true
        },
        function(error, response, body) {
            assert.equal(response.statusCode, 200);
            assert.equal(body[messageBox.common.deleted], 1);
            done();
        });
    });
});    