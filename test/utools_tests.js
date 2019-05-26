//util unit tests
var chai  = require('chai');
chai.use(require('chai-datetime'))
var assert  = chai.assert;

var util = require('../app/tools/util');
const request = require("supertest");
var ver = '/v1.0';
var ut_routes = require('../app/routes/ut_routes');
const app = util.expressInstance();
let config = require('../config/config')
ut_routes(app);

describe('util', function() {
    describe('errors handling', function() {
        it('handleUserException', function(done) {            
            request(app)
            .get(ver + '/handleUserException')            
            .end(function(err, res) { 
                assert.equal(res.status, 400);
                assert.include(res.body.error, 'error_message');
                done();
              });              
        });
    });
    
    describe('expressInstance', function() {
        it('isObject ', function(done) {            
            let expr = util.expressInstance();
            assert.equal(typeof expr._router, 'function');
            done();
        });
    });
    it('renameProperty', function(done) {
        let expected = {new_name: 'obj_name', val: 1};
        let initial = {name: 'obj_name', val: 1};
        assert.equal(util.renameProperty(initial, 'name', 'new_name').toString(), expected.toString());
        done();
    });      

    describe('small tools and helpers', function() {
        it('getDateTime ', function(done) {            
            assert.equalDate(util.getDateTime(), new Date());
            assert.equalTime(util.getDateTime(), new Date());
            done();
        });       
            
        it('getMinDateTime ', function(done) {
            let dateTimeArray = ["2018-121-31T20:54:23.071Z", "2018-12-30T20:54:23.071Z", "2015-01-31T20:54:23.071Z", "2023-01-31T20:54:23.071Z"];            
            let correctResult = util.parseDateTime("2015-01-31T20:54:23.071Z");
            assert.equalDate(util.getMinDateTime(dateTimeArray), correctResult);
            assert.equalTime(util.getMinDateTime(dateTimeArray), correctResult);
            done();
        });       
        
    });
});    
