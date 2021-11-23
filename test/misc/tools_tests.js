/* eslint-disable no-undef */
//util unit tests
var chai = require("chai");
chai.use(require("chai-datetime"));
var assert = chai.assert;

var util = require("../../app/tools/util");
let config = require("../../config/config");
let enableDebugOutput;

const dbclient = require("../../app/tools/db");

describe("util", function () {
  before(() => {
    //temporary disable debug output due to have clear test output
    enableDebugOutput = config.enableDebugOutput;
    config.enableDebugOutput = false;
  });

  after(() => {
    //restore initial debug output
    config.enableDebugOutput = enableDebugOutput;
  });

  describe("1 errors handling", function () {
    it("1.1 logServerError. No user", async function () {
      let logId = await util.logServerError(new Error("dummy"));
      assert.isNumber(logId);
    });
    it("1.2 logServerError. User=1", async function () {
      let logId = await util.logServerError(new Error("dummy"), 1);
      assert.isNumber(logId);
    });
  });

  describe("2 expressInstance", function () {
    it("2.1 isObject ", function (done) {
      let expr = util.expressInstance();
      assert.equal(typeof expr._router, "function");
      done();
    });
  });

  describe("3 DB", function () {
    it("3.1 executeSysQuery. No callback, return Promis ", async function () {
      let db = dbclient.executeSysQuery({ text: "SELECT now()" });
      let result = await db;
      assert.equalDate(result.rows[0].now, new Date());
    });
    it("3.2 executeSysQuery. No connection string, return null ", function (done) {
      let db = dbclient.userQuery({ text: "SELECT now()" });
      assert.isNull(db);
      done();
    });
  });

  describe("4 small tools and helpers", function () {
    it("4.1 getDateTime ", function (done) {
      assert.equalDate(util.getDateTime(), new Date());
      assert.equalTime(util.getDateTime(), new Date());
      done();
    });

    it("4.2 getMinDateTime ", function (done) {
      let dateTimeArray = [
        "2018-121-31T20:54:23.071Z",
        "2018-12-30T20:54:23.071Z",
        "2015-01-31T20:54:23.071Z",
        "2023-01-31T20:54:23.071Z",
      ];
      let correctResult = util.parseDateTime("2015-01-31T20:54:23.071Z");
      assert.equalDate(util.getMinDateTime(dateTimeArray), correctResult);
      assert.equalTime(util.getMinDateTime(dateTimeArray), correctResult);
      done();
    });
    it("4.4 isNumber", function (done) {
      assert.equal(util.isNumber(4, 5), 4);
      assert.equal(util.isNumber(null, 1), 1);
      assert.equal(util.isNumber("3", 1), 3);
      assert.equal(util.isNumber("test", 1), 1);
      assert.equal(util.isNumber(undefined, 7), 7);
      done();
    });

    it("4.5 common pagination. 1st page", function (done) {
      let pag = util.pagination("pornhub.com", 10, 1, 100, "filter", "sort");
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
      let pag = util.pagination("pornhub.com", 10, 10, 95, "filter", "sort");
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
