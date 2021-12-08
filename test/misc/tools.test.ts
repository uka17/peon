/* eslint-disable no-undef */
//util unit tests
import chai from "chai";
chai.use(require("chai-datetime"));
const assert = chai.assert;

import * as util from "../../src/tools/util";
import config from "../../src/config/config";
let enableDebugOutput;

import * as dbclient from "../../src/tools/db";

describe("util", function () {
  before(() => {
    //temporary disable debug output due to have clear test output
    enableDebugOutput = Boolean(config.enableDebugOutput);
    Boolean(config.enableDebugOutput) = false;
  });

  after(() => {
    //restore initial debug output
    Boolean(config.enableDebugOutput) = enableDebugOutput;
  });

  describe("1 errors handling", function () {
    it("1.1 logServerError. No user", async function () {
      const logId = await util.logServerError(new Error("dummy"));
      assert.isNumber(logId);
    });
    it("1.2 logServerError. User=1", async function () {
      const logId = await util.logServerError(
        new Error("dummy"),
        config.testUser
      );
      assert.isNumber(logId);
    });
  });

  describe("2 expressInstance", function () {
    it("2.1 isObject ", function (done) {
      const expr = util.expressInstance();
      assert.equal(typeof expr._router, "function");
      done();
    });
  });

  describe("3 DB", function () {
    it("3.1 executeSysQuery. No callback, return Promis ", async function () {
      const db = dbclient.executeSysQuery({ text: "SELECT now()" });
      const result = await db;
      assert.equalDate(
        (result!.rows[0] as unknown as Record<string, unknown>).now as Date,
        new Date()
      );
    });
  });

  describe("4 small tools and helpers", function () {
    it("4.1 getDateTime ", function (done) {
      assert.equalDate(util.getDateTime(), new Date());
      assert.equalTime(util.getDateTime(), new Date());
      done();
    });

    it("4.2 getMinDateTime ", function (done) {
      const dateTimeArray = [
        "2018-121-31T20:54:23.071Z",
        "2018-12-30T20:54:23.071Z",
        "2015-01-31T20:54:23.071Z",
        "2023-01-31T20:54:23.071Z",
      ];
      const correctResult = util.parseDateTime("2015-01-31T20:54:23.071Z");
      assert.equalDate(
        util.getMinDateTime(dateTimeArray),
        correctResult as Date
      );
      assert.equalTime(
        util.getMinDateTime(dateTimeArray),
        correctResult as Date
      );
      done();
    });
    it("4.4 isNumber", function (done) {
      assert.equal(util.isNumber("4", 5), 4);
      assert.equal(util.isNumber(null, 1), 1);
      assert.equal(util.isNumber("3", 1), 3);
      assert.equal(util.isNumber("test", 1), 1);
      assert.equal(util.isNumber(undefined, 7), 7);
      done();
    });

    it("4.5 common pagination. 1st page", function (done) {
      const pag = util.pagination("pornhub.com", 10, 1, 100, "filter", "sort");
      assert.equal(pag.last_page, 10);
      assert.equal(
        pag.next_page_url,
        "pornhub.com/?page=2&per_page=10&filter=filter&sort=sort"
      );
      assert.isNull(pag.prev_page_url);
      assert.equal(pag.from, 1);
      assert.equal(pag.to, 10);
      done();
    });

    it("4.6 common pagination. Last page", function (done) {
      const pag = util.pagination("pornhub.com", 10, 10, 95, "filter", "sort");
      assert.equal(pag.last_page, 10);
      assert.isNull(pag.next_page_url);
      assert.equal(
        pag.prev_page_url,
        "pornhub.com/?page=9&per_page=10&filter=filter&sort=sort"
      );
      assert.equal(pag.from, 91);
      assert.equal(pag.to, 95);
      done();
    });
  });
});
