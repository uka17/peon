/* eslint-disable no-undef */
let objectId;
import * as util from "../../src/tools/util";
import request from "supertest";
import { assert } from "chai";
import labels from "../../src/config/message_labels";
const messageBox = labels("en");
import config from "../../src/config/config";
import express from "express";

/**
 * Imlements set of unit tests for standart api route, which incudes all basic CRUD actions like: list, count, post, get, patch, delete.
 * @param {string} apiRoute URL for api part including version. Starts with /. Example: '/v1.0/job'
 * @param {object} routeObject Route object to be used to test api route
 * @param {object} testReferenceObject Correct object which will be used for tests
 * @param {string} referenceFieldName Name of object field which will be used for 'incorrect field type' and 'patch' tests
 * @param {string} referenceFieldType Type of object field which will be used for 'incorrect field type' and 'patch' tests
 * @param {string} entity Name of entity which is being tested
 */
export default function testApiRoute(
  apiRoute: string,
  routeObject: (app: express.Application) => void,
  testReferenceObject: Record<string, unknown>,
  referenceFieldName: string,
  referenceFieldType: string,
  entity: string
) {
  config.user = "testRobot";
  const inst = util.expressInstance();
  routeObject(inst);
  describe("api test for: " + apiRoute, function () {
    //sometimes test for creation of objectId is being executed late and objectId becomes undefined
    before((done) => {
      request(inst)
        .post(apiRoute)
        .send(testReferenceObject)
        .set("Accept", "application/json")
        .end(function (err, res) {
          objectId = res.body.id;
          done();
        });
    });

    it(`1.1 incorrect '${referenceFieldName}' type, expected type is '${referenceFieldType}'`, (done) => {
      const nObject = JSON.parse(JSON.stringify(testReferenceObject));
      //assign incorrect value to reference field in order to have failed test
      switch (referenceFieldType) {
        case "string":
          nObject[referenceFieldName] = true;
          break;
        case "number":
          nObject[referenceFieldName] = true;
          break;
        case "boolean":
          nObject[referenceFieldName] = 123;
          break;
        case "array":
          nObject[referenceFieldName] = true;
          break;
        case "object":
          nObject[referenceFieldName] = true;
          break;
      }
      request(inst)
        .post(apiRoute)
        .send(nObject)
        .set("Accept", "application/json")
        .end(function (err, res) {
          assert.equal(res.status, 400);
          assert.include(res.body.requestValidationErrors, referenceFieldName);
          done();
        });
    });

    it("1.2 successful POST", (done) => {
      request(inst)
        .post(apiRoute)
        .send(testReferenceObject)
        .set("Accept", "application/json")
        .end(function (err, res) {
          assert.equal(res.status, 201);
          const testObject = res.body.body;
          assert.equal(
            testObject[referenceFieldName],
            testReferenceObject[referenceFieldName]
          );
          objectId = res.body.id;
          done();
        });
    });
    it("1.3 failed POST (405)", (done) => {
      request(inst)
        .post(apiRoute + "/" + objectId)
        .send(testReferenceObject)
        .set("Accept", "application/json")
        .end(function (err, res) {
          assert.equal(res.status, 405);
          done();
        });
    });
    it("1.4.1 successful count", (done) => {
      request(inst)
        .get(apiRoute + "/count")
        .set("Accept", "application/json")
        .end(function (err, res) {
          assert.equal(res.status, 200);
          assert.isAbove(res.body[messageBox.common.count], 0);
          done();
        });
    });
    it("1.4.2 empty count", (done) => {
      request(inst)
        .get(apiRoute + "/count?filter=biteme")
        .set("Accept", "application/json")
        .end(function (err, res) {
          assert.equal(res.status, 200);
          assert.equal(res.body[messageBox.common.count], 0);
          done();
        });
    });
    it("1.5 failed get (404)", (done) => {
      request(inst)
        .get(apiRoute + "/0")
        .set("Accept", "application/json")
        .end(function (err, res) {
          assert.equal(res.status, 404);
          done();
        });
    });
    it("1.6.1 successful list", (done) => {
      request(inst)
        .get(apiRoute)
        .set("Accept", "application/json")
        .end(function (err, res) {
          assert.equal(res.status, 200);
          assert.isAbove(res.body.data.length, 0);
          done();
        });
    });
    it("1.6.2 successful list with params", (done) => {
      request(inst)
        .get(`${apiRoute}?filter=o&sort=id|asc&page=1&perPage=1`)
        .set("Accept", "application/json")
        .end(function (err, res) {
          assert.equal(res.status, 200);
          assert.isAbove(res.body.data.length, 0);
          done();
        });
    });
    it('1.6.3 successful list with partial "sort" params', (done) => {
      request(inst)
        .get(`${apiRoute}?filter=o&sort=id&page=1&perPage=1`)
        .set("Accept", "application/json")
        .end(function (err, res) {
          assert.equal(res.status, 200);
          assert.isAbove(res.body.data.length, 0);
          done();
        });
    });
    it("1.7 successful get", (done) => {
      request(inst)
        .get(apiRoute + "/" + objectId)
        .set("Accept", "application/json")
        .end(function (err, res) {
          assert.equal(res.status, 200);
          assert.isTrue("id" in res.body);
          done();
        });
    });

    it("1.8 successful patch", (done) => {
      const nObject = JSON.parse(JSON.stringify(testReferenceObject));
      //assign correct value to reference field in order to have success patch test
      switch (referenceFieldType) {
        case "string":
          nObject[referenceFieldName] = "test";
          break;
        case "number":
          nObject[referenceFieldName] = 123;
          break;
        case "boolean":
          nObject[referenceFieldName] = true;
          break;
        case "array":
          nObject[referenceFieldName] = [];
          break;
        case "object":
          nObject[referenceFieldName] = {};
          break;
      }
      request(inst)
        .patch(apiRoute + "/" + objectId)
        .send(nObject)
        .set("Accept", "application/json")
        .end(function (err, res) {
          assert.equal(res.statusCode, 200);
          assert.equal(res.body[messageBox.common.updated], 1);
          done();
        });
    });

    it("1.9 successful delete", (done) => {
      request(inst)
        .delete(apiRoute + "/" + objectId)
        .set("Accept", "application/json")
        .end(function (err, res) {
          assert.equal(res.statusCode, 200);
          assert.equal(res.body[messageBox.common.deleted], 1);
          done();
        });
    });
  });
}
