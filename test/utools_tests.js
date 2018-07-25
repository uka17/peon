//utools unit tests
var assert  = require('chai').assert;
let chai = require('chai');
var config = require('../config/config');
var utools = require('../app/tools/utools');
var validation = require('../app/tools/validations');
var models = require('../app/models/app_models');
var testData = require('./test_data');
const httpMocks = require("node-mocks-http");
var app = require('../server').app;
const request = require("supertest");
var ver = '/v1.0';


describe('utools', function() {
    describe('errors handling', function() {

    });

    describe('tools and helpers', function() {
        it('getTimestamp ', function(done) {
            assert.equal(utools.getTimestamp().toString(), new Date());
            done();
        });   
        it('renameProperty', function(done) {
            let expected = {new_name: 'obj_name', val: 1};
            let initial = {name: 'obj_name', val: 1};
            assert.equal(utools.renameProperty(initial, 'name', 'new_name').toString(), expected.toString());
            done();
        });  
        it('addDate', function(done) {
            let initial = new Date(Date.parse('2018-01-31T02:02:02.071Z'));            
            let expected = new Date(Date.parse('2018-01-31T01:01:01.071Z'));
            expected = utools.addDate(expected, 0, 0, 0, 1, 1, 1);
            assert.equal(initial.toDateString(), expected.toDateString());
            done();
        });         
    });

});    