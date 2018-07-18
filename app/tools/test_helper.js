// utools/test_helpers.js
var assert  = require('chai').assert;
var request = require('request');
/**
 * Creates instance of helper for unit testing
 * @param {object} object Initial object which should be tested. This object should not contain any errors in properties
 * @returns {object} Instance of helper
 */
function testHelper(object) {
    this._object = object;
    /**
     * Implements unit test for next scenario: changes propertyName of helper initial object to incorrect and attempts to POST this object.
     * Expected result: 400 HTTP response (error)
     * @param {string} url URL for sending POST request
     * @param {string} propertyName Name of property which should be checked
     * @param {string} propertyType Type of property which should be checked. One of the list: number, integer, string, boolean, array, object, enum
     */
    this.failedPostTest = (url, propertyName, propertyType) => {
        var object = this._object;
        it('incorrect "' + propertyName + '" type (exp: ' + propertyType + ') POST attempt', function(done) {            
            let nObject = JSON.parse(JSON.stringify(object));            
            //put a mistake into object
            switch(propertyType) {
                case "string":
                nObject[propertyName] = true;
                break;
                case "number":
                nObject[propertyName] = 'string';
                break;
                case "integer":
                nObject[propertyName] = 'string';
                break;
                case "boolean":
                nObject[propertyName] = 777;
                break;
                case "array":
                nObject[propertyName] = 1;
                break;
                case "object":
                nObject[propertyName] = 777;
                break;       
                case "enum":
                nObject[propertyName] = 777;
                break;                                
            }            
            request.post({
                url: url,  
                json: nObject
            }, 
            function(error, response, body) {
                assert.equal(response.statusCode, 400);
                done();
            });
        });
    }
    /**
     * Implement list of unit tests to compare each and every property of helper initial object and objectToCheck     
     * @param {object} objectToCheck 
     */
    this.compareObjects = (objectToCheck) => {        
        Object.keys(this._object).forEach(elem => assert.equal(this._object[elem], objectToCheck[elem]))
    }
   
}

module.exports = testHelper;