/* eslint-disable no-undef */
const testData = require("../data/application");
import { assert } from "chai";
let enableDebugOutput;
import Connection from "../../app/classes/connection";
import config from "../../config/config";
const connection: Connection = null;

describe("1 connection engine", function () {
  this.timeout(500000);

  before(async () => {
    //temporary disable debug output due to have clear test output
    enableDebugOutput = config.enableDebugOutput;
    config.enableDebugOutput = false;
    connection = await Connection.save(testData.connectionOK, config.testUser);
  });

  after(() => {
    //restore initial debug output
    config.enableDebugOutput = enableDebugOutput;
  });

  });

  it("1.3.1 createConnection. Type mismatch `connection`", async () => {
    try {
      await Connection.createConnection(1);
    } catch (e) {
      assert.include(e.stack, "connection should be an object");
    }
  });
  it("1.3.2 createConnection. Type mismatch `createdBy`", async () => {
    try {
      await Connection.createConnection({}, 1);
    } catch (e) {
      assert.include(e.stack, "createdBy should be a string");
    }
  });

  it("1.4.1 updateConnection. Type mismatch `connectionId`", async () => {
    try {
      await Connection.updateConnection("a");
    } catch (e) {
      assert.include(e.stack, "connectionId should be a number");
    }
  });
  it("1.4.2 updateConnection. Type mismatch `connection`", async () => {
    try {
      await Connection.updateConnection(1, "a");
    } catch (e) {
      assert.include(e.stack, "connection should be an object");
    }
  });
  it("1.4.3 updateConnection. Type mismatch `updatedBy`", async () => {
    try {
      await Connection.updateConnection(1, {}, 1);
    } catch (e) {
      assert.include(e.stack, "updatedBy should be a string");
    }
  });

  it("1.5.1 updateConnection. Type mismatch `connectionId`", async () => {
    try {
      await Connection.deleteConnection("a");
    } catch (e) {
      assert.include(e.stack, "connectionId should be a number");
    }
  });
  it("1.5.2 updateConnection. Type mismatch `deletedBy`", async () => {
    try {
      await Connection.deleteConnection(1, 1);
    } catch (e) {
      assert.include(e.stack, "deletedBy should be a string");
    }
  });
});
