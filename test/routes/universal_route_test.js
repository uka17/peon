var objectId;   

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
    let config = require('../../config/config');
    config.user = 'testRobot';
    console.log(config.useDBSSL);
    console.log(config.connectionString);

    describe('api test for: ' + apiRoute, function() {
        //sometimes test for creation of objectId is being executed late and objectId becomes undefined
        before((done) => {
            request(inst.app)
                .post(apiRoute)            
                .send(testReferenceObject)
                .set('Accept', 'application/json')
                .end(function(err, res) {                     
                    objectId = res.body.id;
                    done();
                });                            
        }); 

        it(`incorrect '${referenceFieldName}' type, expected type is '${referenceFieldType}'`, (done) => {                        
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
                    done();
                });                    
        });   

        it('successful POST', (done) => {                    
            request(inst.app)
                .post(apiRoute)            
                .send(testReferenceObject)
                .set('Accept', 'application/json')
                .end(function(err, res) {               
                    assert.equal(res.status, 201);
                    assert.equal(res.body[referenceFieldName], testReferenceObject[referenceFieldName]);
                    objectId = res.body.id;
                    done();
                });                    
        });  
        it('failed POST (405)', (done) => {
            request(inst.app)
                .post(apiRoute + '/' + objectId)            
                .send(testReferenceObject)
                .set('Accept', 'application/json')
                .end(function(err, res) { 
                    assert.equal(res.status, 405);
                    done();
                });                    
        });          
        it('successful count', (done) => {
            request(inst.app)
                .get(apiRoute + '/count')            
                .set('Accept', 'application/json')
                .end(function(err, res) { 
                    assert.equal(res.status, 200);
                    assert.isAbove(res.body[messageBox.common.count], 0);
                    done();
                });                    
        });  
        it('failed get (404)', (done) => {
            request(inst.app)                           
                .get(apiRoute + '/0')            
                .set('Accept', 'application/json')
                .end(function(err, res) { 
                    assert.equal(res.status, 404);   
                    done();                                
                });                    
        });             
        it('successful list', (done) => {                              
            request(inst.app)
                .get(apiRoute)            
                .set('Accept', 'application/json')
                .end(function(err, res) { 
                    assert.equal(res.status, 200);
                    assert.isAbove(res.body.length, 0);
                    done();
                });                    
        });  

        it('successful get', (done) => {
            request(inst.app)                                     
                .get(apiRoute + '/' + objectId)            
                .set('Accept', 'application/json')
                .end(function(err, res) { 
                    assert.equal(res.status, 200);                                   
                    assert.isTrue(res.body.hasOwnProperty("id"));
                    done();
                });                    
        });           

        it('successful patch', (done) => {                         
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
                    assert.equal(res.body[messageBox.common.updated], 1);
                    done();
                });                    
        });   
      
        it('successful delete', (done) => {
            request(inst.app)                      
                .delete(apiRoute + '/' + objectId)            
                .set('Accept', 'application/json')
                .end(function(err, res) { 
                    assert.equal(res.statusCode, 200);
                    assert.equal(res.body[messageBox.common.deleted], 1)
                    done();
                });              
        });                                 
    });
}

