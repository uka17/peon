/**
 * Imlements set of unit tests for standart api route, which incudes all basic CRUD actions like: list, count, post, get, patch, delete.
 * @param {string} apiRoute URL for api part including version. Starts with /. Example: '/v1.0/job'
 * @param {object} routeObject Route object to be used to test api route
 * @param {object} testReferenceObject Correct object which will be used for tests
 * @param {string} referenceFieldName Name of object field which will be used for 'incorrect field type' and 'patch' tests
 * @param {string} referenceFieldType Type of object field which will be used for 'incorrect field type' and 'patch' tests
 */
module.exports.testApiRoute = (apiRoute, routeObject, testReferenceObject, referenceFieldName, referenceFieldType) => {
    const request = require("supertest");
    var assert  = require('chai').assert;
    const config = require('../config/config');
    var messageBox = require('../config/message_labels');    
    var utools = require('../app/tools/utools');
    var testHelper = require('./test_helper');
    var objectTestHelper = new testHelper(testReferenceObject);
    var objectId;   

    describe('api test for: ' + apiRoute, function() {
        it(`incorrect '${referenceFieldName}' type, expected type is '${referenceFieldType}'`, () => {
            return utools.expressMongoInstancePromise(routeObject, config.mongodb_url).then(response => {                               
                let nObject = JSON.parse(JSON.stringify(testReferenceObject));
                //assign incorrect value to reference field in order to have failed test
                switch(referenceFieldType) {
                    case 'string':
                    nObject[referenceFieldName] = true;
                    break;
                    case 'number':
                    nObject[referenceFieldName] = true;
                    break;
                    case 'boolean':
                    nObject[referenceFieldName] = 123;
                    break;
                    case 'array':
                    nObject[referenceFieldName] = true;
                    break;
                    case 'object':
                    nObject[referenceFieldName] = true;
                    break;
                }
                request(response.app)
                .post(apiRoute)            
                .send(nObject)
                .set('Accept', 'application/json')
                .end(function(err, res) { 
                    assert.equal(res.status, 400);
                    assert.include(res.body.requestValidationErrors, referenceFieldName);
                    response.dbclient.close();
                });                    
            }); 
        });   
        it('successful POST', () => {
            return utools.expressMongoInstancePromise(routeObject, config.mongodb_url).then(response => {                               
                request(response.app)
                    .post(apiRoute)            
                    .send(testReferenceObject)
                    .set('Accept', 'application/json')
                    .end(function(err, res) { 
                        assert.equal(res.status, 201);
                        assert.equal(res.body[referenceFieldName], testReferenceObject[referenceFieldName]);
                        objectId = res.body._id;
                        response.dbclient.close()
                    });                    
            }); 
        });  
        it('failed POST (405)', () => {
            return utools.expressMongoInstancePromise(routeObject, config.mongodb_url).then(response => {                               
                request(response.app)
                    .post(apiRoute + '/' + objectId)            
                    .send(testReferenceObject)
                    .set('Accept', 'application/json')
                    .end(function(err, res) { 
                        assert.equal(res.status, 405);
                        response.dbclient.close()
                    });                    
            }); 
        });          
        it('successful count', () => {
            return utools.expressMongoInstancePromise(routeObject, config.mongodb_url).then(response => {                               
                request(response.app)
                    .get(apiRoute + '/count')            
                    .set('Accept', 'application/json')
                    .end(function(err, res) { 
                        assert.equal(res.status, 200);
                        assert.isAbove(res.body[messageBox.common.count], 0);
                        response.dbclient.close()
                    });                    
            }); 
        });  
        it('successful get', () => {
            return utools.expressMongoInstancePromise(routeObject, config.mongodb_url).then(response => {                               
                request(response.app)
                    .get(apiRoute + '/' + objectId)            
                    .set('Accept', 'application/json')
                    .end(function(err, res) { 
                        assert.equal(res.status, 200);
                        objectTestHelper.compareObjects(res.body);
                        response.dbclient.close()
                    });                    
            }); 
        });     
        it('successful list', () => {
            return utools.expressMongoInstancePromise(routeObject, config.mongodb_url).then(response => {                               
                request(response.app)
                    .get(apiRoute)            
                    .set('Accept', 'application/json')
                    .end(function(err, res) { 
                        assert.equal(res.statusCode, 200);
                        assert.isAbove(res.body.length, 0);
                        response.dbclient.close()
                    });                    
            }); 
        });     
        it('successful patch', () => {
            return utools.expressMongoInstancePromise(routeObject, config.mongodb_url).then(response => {                               
                let nObject = JSON.parse(JSON.stringify(testReferenceObject));
                //assign correct value to reference field in order to have success patch test
                switch(referenceFieldType) {
                    case 'string':
                    nObject[referenceFieldName] = 'test';
                    break;
                    case 'number':
                    nObject[referenceFieldName] = 123;
                    break;
                    case 'boolean':
                    nObject[referenceFieldName] = true;
                    break;
                    case 'array':
                    nObject[referenceFieldName] = [];
                    break;
                    case 'object':
                    nObject[referenceFieldName] = {};
                    break;
                }
                request(response.app)
                    .patch(apiRoute + '/' + objectId)            
                    .send(nObject)
                    .set('Accept', 'application/json')
                    .end(function(err, res) { 
                        assert.equal(res.statusCode, 200);
                        assert.equal(res.body[messageBox.common.updated], 1)
                        response.dbclient.close()
                    });                    
            }); 
        });             
        it('successful delete', () => {
            return utools.expressMongoInstancePromise(routeObject, config.mongodb_url).then(response => {                               
                request(response.app)
                    .delete(apiRoute + '/' + objectId)            
                    .set('Accept', 'application/json')
                    .end(function(err, res) { 
                        assert.equal(res.statusCode, 200);
                        assert.equal(res.body[messageBox.common.deleted], 1)
                        response.dbclient.close()
                    });                    
            }); 
        });                                    
    });
}

