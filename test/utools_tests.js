//utools unit tests
var chai  = require('chai');
chai.use(require('chai-datetime'))
var assert  = chai.assert;

var utools = require('../app/tools/utools');
const request = require("supertest");
var ver = '/v1.0';
var ut_routes = require('../app/routes/ut_routes');
const app = utools.expressInstance();
let config = require('../config/config')
ut_routes(app);

describe('utools', function() {
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
    
    describe('expressMongoInstancePromise', function() {
        it('basic validation', () => {       
            return utools.expressMongoInstancePromise(ut_routes, config.mongodb_url).then(response => {
                //I hate to write UT for promises
                assert.equal(response.hasOwnProperty('dbclient'), true);
                assert.equal(response.hasOwnProperty('app'), true);
                response.dbclient.close();
            });
        });
    });
    
    describe('expressInstance', function() {
        it('isObject ', function(done) {            
            let expr = utools.expressInstance();
            assert.equal(typeof expr._router, 'function');
            done();
        });
    });
    it('renameProperty', function(done) {
        let expected = {new_name: 'obj_name', val: 1};
        let initial = {name: 'obj_name', val: 1};
        assert.equal(utools.renameProperty(initial, 'name', 'new_name').toString(), expected.toString());
        done();
    });      

    describe('small tools and helpers', function() {
        it('getDateTime ', function(done) {            
            assert.equalDate(utools.getDateTime(), new Date());
            assert.equalTime(utools.getDateTime(), new Date());
            done();
        });           
    });
});    
