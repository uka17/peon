//utools unit tests

var assert  = require('chai').assert;
let chai = require('chai');
var request = require('request');
var config = require('../config/config');
var utools = require('../app/tools/utools');
var validation = require('../app/tools/validations');
var models = require('../app/models/app_models');
var testData = require('./test_data');


describe('utools', function() {
    describe('errors handling', function() {
        it('handleServerException', function(done) {
            console.log(config.test_host + '/dummyerror');
            request.post({
                url: config.test_host + '/dummyerror',  
                json: true
            }, 
            function(error, response, body) {
                assert.equal(response.statusCode, 404);
                done();
            });
        });            
    });

});    