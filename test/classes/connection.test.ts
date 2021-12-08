/* eslint-disable no-undef */
import testData from "../data/application";
import { assert } from "chai";
let enableDebugOutput;
import Connection from "../../src/classes/connection";
import ConnectionBody from "../../src/classes/connectionBody";
import config from "../../src/config/config";
let conn: Connection;

describe("1 Connection", function () {
  this.timeout(500000);

  before(async () => {
    //temporary disable debug output due to have clear test output
    enableDebugOutput = Boolean(config.enableDebugOutput);
    config.enableDebugOutput = false;
    conn = new Connection(testData.connectionOK as ConnectionBody);
    await conn.save(config.testUser);
  });

  after(() => {
    //restore initial debug output
    config.enableDebugOutput = enableDebugOutput;
  });

  it("1.1 list. Incorrect sorting parameter", async () => {
    try {
      await Connection.list("a", "id", "zzz", 1, 10);
    } catch (e) {
      assert.include(
        (e as Error).stack,
        "sortOrder should have value `asc` or `desc`"
      );
    }
  });

  it("1.1 list. Empty result", async () => {
    try {
      await Connection.list("ghost-connection", "id", "asc", 1, 10);
    } catch (e) {
      assert.include(
        (e as Error).stack,
        "sortOrder should have value `asc` or `desc`"
      );
    }
  });

  it("1.2 update. Update before save", async () => {
    try {
      const updConn = new Connection(testData.connectionOK as ConnectionBody);
      await updConn.update(config.testUser);
    } catch (e) {
      assert.include((e as Error).stack, "save it before any changes");
    }
  });

  it("1.3 delete. Delete before save", async () => {
    try {
      const delConn = new Connection(testData.connectionOK as ConnectionBody);
      await delConn.delete(config.testUser);
    } catch (e) {
      assert.include((e as Error).stack, "save it before any changes");
    }
  });

  it("1.4 create. Incorrect body", async () => {
    try {
      const delConn = new Connection(
        testData.connectionNOK as unknown as ConnectionBody
      );
      await delConn.save(config.testUser);
    } catch (e) {
      assert.include((e as Error).stack, "Connection body is not valid json");
    }
  });
});
