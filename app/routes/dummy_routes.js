/* istanbul ignore file */
// routes/dummy_routes.js
let util = require("../tools/util");
const config = require("../../config/config");
let jobEngine = require("../engines/job");
let ver = "/v1.0";

module.exports = function (app, dbclient) {
  app.get(ver + "/dummy", (req, res) => {
    //dummy
    try {
      util.handleServerException("Errror!", "sys", dbclient, res);
    } catch (e) {
      res.status(500).send({ error: e.message });
    }
  });
  app.get("/", async (req, res) => {
    //get jobs count
    try {
      let resObject = {};
      resObject["Greeting:"] = "Welcome, comrade!";
      resObject["Deploy status:"] = "Ok";
      resObject["Jobs:"] = await jobEngine.getJobCount();
      res.status(200).send(resObject);
    } catch (e) {
      /* istanbul ignore next */
      util.handleServerException(e, config.user, dbclient, res);
    }
  });
};
