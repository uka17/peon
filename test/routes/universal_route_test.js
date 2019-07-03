var objectId;   
var objectIdDelete;
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
    var messageBox = require('../../config/message_labels')('en');    
    var util = require('../../app/tools/util');   
    let inst = util.expressPostgreInstance(routeObject);

    describe('api test for: ' + apiRoute, function() {
        //sometimes test for creation of objectId is being executed late and objectId becomes undefined
        before(() => {
            request(inst.app)
                .post(apiRoute)            
                .send(testReferenceObject)
                .set('Accept', 'application/json')
                .end(function(err, res) { 
                    assert.equal(res.status, 201);
                    assert.equal(res.body[referenceFieldName], testReferenceObject[referenceFieldName]);
                    objectId = res.body.id;
                });            
            request(inst.app)
                .post(apiRoute)            
                .send(testReferenceObject)
                .set('Accept', 'application/json')
                .end(function(err, res) { 
                    assert.equal(res.status, 201);
                    assert.equal(res.body[referenceFieldName], testReferenceObject[referenceFieldName]);
                    objectIdDelete = res.body.id;
                });                            
        }); 

        it(`incorrect '${referenceFieldName}' type, expected type is '${referenceFieldType}'`, () => {                        
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
            request(inst.app)
                .post(apiRoute)            
                .send(nObject)
                .set('Accept', 'application/json')
                .end(function(err, res) { 
                    assert.equal(res.status, 400);
                    assert.include(res.body.requestValidationErrors, referenceFieldName);
                });                    
        });   

        it('successful POST', () => {                    
            request(inst.app)
                .post(apiRoute)            
                .send(testReferenceObject)
                .set('Accept', 'application/json')
                .end(function(err, res) {               
                    assert.equal(res.status, 201);
                    assert.equal(res.body[referenceFieldName], testReferenceObject[referenceFieldName]);
                    objectId = res.body.id;
                });                    
        });  
        it('failed POST (405)', () => {
            request(inst.app)
                .post(apiRoute + '/' + objectId)            
                .send(testReferenceObject)
                .set('Accept', 'application/json')
                .end(function(err, res) { 
                    assert.equal(res.status, 405);
                });                    
        });          
        it('successful count', () => {
            request(inst.app)
                .get(apiRoute + '/count')            
                .set('Accept', 'application/json')
                .end(function(err, res) { 
                    assert.equal(res.status, 200);
                    assert.isAbove(res.body[messageBox.common.count], 0);
                });                    
        });  
        it('successful get', () => {
            request(inst.app)                           
                .get(apiRoute + '/' + objectId)            
                .set('Accept', 'application/json')
                .end(function(err, res) { 
                    assert.equal(res.status, 200);                                   
                    assert.isTrue(res.body.hasOwnProperty("id"));
                });                    
        });     
        it('failed get (404)', () => {
            request(inst.app)                           
                .get(apiRoute + '/0')            
                .set('Accept', 'application/json')
                .end(function(err, res) { 
                    assert.equal(res.status, 404);                                   
                });                    
        });         
        it('successful list', () => {                              
            request(inst.app)
                .get(apiRoute)            
                .set('Accept', 'application/json')
                .end(function(err, res) { 
                    assert.equal(res.status, 200);
                    assert.isAbove(res.body.length, 0);
                });                    
        });     

        it('successful patch', () => {                         
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
            request(inst.app)
                .patch(apiRoute + '/' + objectId)            
                .send(nObject)
                .set('Accept', 'application/json')
                .end(function(err, res) {         
                    assert.equal(res.statusCode, 200);
                    assert.equal(res.body[messageBox.common.updated], 1)
                });                    
        });   
      
        it('successful delete', () => {
            request(inst.app)                      
                .delete(apiRoute + '/' + objectIdDelete)            
                .set('Accept', 'application/json')
                .end(function(err, res) { 
                    assert.equal(res.statusCode, 200);
                    assert.equal(res.body[messageBox.common.deleted], 1)
                });              
        });                                        
    });
}

