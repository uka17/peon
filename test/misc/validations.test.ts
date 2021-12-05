/* eslint-disable no-undef */
//validation unit tests
import { assert } from "chai";
import validation from "../../src/tools/validation";
import testData from "../data/application";
import ConnectionBody from "../../src/classes/connectionBody";
import JobBody from "../../src/classes/jobBody";

describe("validation", function () {
  describe("1 validateConnection", function () {
    it("1.1 OK (" + testData.connectionOK.name + ")", function (done) {
      assert.equal(
        validation.validateConnection(testData.connectionOK as ConnectionBody)
          .isValid,
        true
      );
      done();
    });

    testData.connectionNOK.forEach((element, index) => {
      it(
        "1.2." + index.toString() + " NOK (" + element.name + ")",
        function (done) {
          assert.equal(
            validation.validateConnection(element as ConnectionBody).isValid,
            false
          );
          done();
        }
      );
    });
  });

  describe("3 validateJob", function () {
    it("3.1 OK (" + testData.jobBodyOK.name + ")", function (done) {
      assert.equal(
        validation.validateJob(testData.jobBodyOK as unknown as JobBody)
          .isValid,
        true
      );
      done();
    });
  });

  describe("4 validateStepList", function () {
    it("4.1 OK (" + testData.jobBodyOK.name + ".steps)", function (done) {
      const nJob = JSON.parse(
        JSON.stringify(testData.jobBodyOK as unknown as JobBody)
      );
      assert.equal(validation.validateStepList(nJob.steps).isValid, true);
      done();
    });

    it("4.2 NOK (" + testData.jobBodyOK.name + ".steps)", function (done) {
      const nJob = JSON.parse(JSON.stringify(testData.jobBodyOK));
      nJob.steps[0].name = true;
      assert.equal(validation.validateStepList(nJob.steps).isValid, false);
      done();
    });
  });
});
