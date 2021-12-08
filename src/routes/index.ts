// routes/index.js
import dummyRoutes from "./dummy_routes";
import userRoutes from "./user_routes";
import jobRoutes from "./job_routes";
import connectionRoutes from "./connection_routes";
import express from "express";
import message_labels from "../config/message_labels";
const labels = message_labels("en");
import LogDispatcher from "../classes/logDispatcher";
import config from "../config/config";
const log = LogDispatcher.getInstance(
  Boolean(config.enableDebugOutput),
  config.logLevel
);

/**
 * Main router
 * @param {express.Application} app Express instance
 */
export default function (app: express.Application) {
  dummyRoutes(app);
  jobRoutes(app);
  userRoutes(app);
  connectionRoutes(app);
  //Error handlers
  app.use(function (
    err: express.ErrorRequestHandler,
    req: express.Request,
    res: express.Response,
    next: express.NextFunction
  ) {
    if (err) {
      if (err.name === "UnauthorizedError") {
        res.status(401).send({ error: labels.user.incorrectToken });
      } else {
        log.error(err);
      }
    }
    next();
  });
}
