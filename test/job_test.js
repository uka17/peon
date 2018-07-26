var assert  = require('chai').assert;
const config = require('../config/config');
var messageBox = require('../config/message_labels');
var id;
var testData = require('./test_data');
var testHelper = require('../app/tools/test_helper');
var utools = require('../app/tools/utools');
const request = require("supertest");
var ver = '/v1.0';
var job_routes = require('../app/routes/job_routes');
describe('job', function() {
    describe('create', function() {        
        utools.mongoInstancePromise(config.mongodb_url).then(dbclient => {
            console.log(dbclient);
            let app = utools.expressAppInstance();
            job_routes(app, dbclient);                     
            it('incorrect "description"', function(done) {
                console.log('nail');
                request(app)
                .post(ver + '/jobs')            
                .send({"name": "name", "description": true, "enabled": true})
                .set('Accept', 'application/json')
                .expect(400)
                .end(function(err, res) { 
                    assert.include(res.body.requestValidationErrors, 'description');
                    done();
                });    
            });     
        })
    })
}); 
