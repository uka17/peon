// routes/index.js
const dummyRoutes = require("./dummy_routes");
const userRoutes = require("./user_routes");
const jobRoutes = require("./job_routes");
const connectionRoutes = require("./connection_routes");
const labels = require("../../config/message_labels")("en");
const log = require("../../log/dispatcher");

/**
 * Main router
 * @param {object} app Express instance
 * @param {object} dbclient DB connection instance
 */
module.exports = function (app, dbclient) {
  dummyRoutes(app, dbclient);
  jobRoutes(app);
  userRoutes(app);
  connectionRoutes(app, dbclient);
  //Error handlers
  app.use(function (err, req, res, next) {
    if (err) {
      if (err.name === "UnauthorizedError") {
        res.status(401).send({ error: labels.user.incorrectToken });
      } else {
        log.error(err);
      }
    }
    next();
  });
};
