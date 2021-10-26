// util/test_helpers.js
var assert = require("chai").assert;
var request = require("request");
var messageBox = require("../config/message_labels")("en");

/**
 * Creates instance of helper for unit testing
 * @param {object} object Initial object which should be tested. This object should not contain any errors in properties
 * @returns {object} Instance of helper
 */
function testHelper(object) {
  this._object = object;
  /**
   * Implement list of unit tests to compare each and every property of helper initial object and objectToCheck in a shallow mode (compares everything except objects)
   * @param {object} objectToCheck
   */
  //TODO Realize object comarison
  this.compareObjects = (objectToCheck) => {
    Object.keys(this._object).forEach((elem) => {
      if (typeof this._object[elem] != "object")
        assert.equal(this._object[elem], objectToCheck[elem]);
    });
  };
  /**
   * For each an every object in helper initial object array executes: object creation via POST to url, shallow check of created object, deletion of this object
   * @param {string} url URL for sending POST request
   */
  this.createFromList = (url) => {
    var id;
    this._object.forEach((element) => {
      it("creating element, checking and deleting at " + url, function (done) {
        //creation
        request.post(
          {
            url: url,
            json: element,
          },
          function (error, response, body) {
            //shallow check
            Object.keys(element).forEach((key) => {
              if (typeof element[key] != "object")
                assert.equal(element[key], body[key]);
            });
            assert.exists(body._id);
            id = body._id;
            //deletion
            request.delete(
              {
                url: url + "/" + id,
                json: true,
              },
              function (error, response, body) {
                assert.equal(response.statusCode, 200);
                assert.equal(body[messageBox.common.deleted], 1);
                done();
              }
            );
          }
        );
      });
    });
  };
}
module.exports = testHelper;
