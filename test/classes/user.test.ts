//most of the code covered by user_routes.test.ts
import User from "../../src/classes/user";
import { nanoid } from "nanoid";
import config from "../../src/config/config";
import sinon from "sinon";
import { assert } from "chai";
import chaiAsPromised from "chai-as-promised";
import chai from "chai";
chai.use(chaiAsPromised);

describe("1 user class", function () {
  it("1.1 save. Can not find saved User", async () => {
    const errorTag = nanoid();
    const stub1 = sinon.stub(User, "getById").rejects(new Error(errorTag));
    const user = new User("kot@" + nanoid() + ".com");
    //TODO stub doesn't work with sinon.isRejected. Find out why
    try {
      await user.save(config.testUser);
    } catch (e) {
      assert.include((e as Error).message, errorTag);
    } finally {
      stub1.restore();
    }
  });
});
