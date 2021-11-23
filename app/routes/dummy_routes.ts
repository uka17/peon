/* istanbul ignore file */
import * as util from "../tools/util";
import config from "../../config/config";
import Job from "../classes/job";
import express from "express";
import message_labels from "../../config/message_labels";
const labels = message_labels("en");

export default function (app: express.Application) {
  app.get("/", async (req, res) => {
    //get jobs count
    try {
      const resObject = {};
      resObject["Greeting:"] = "Welcome, comrade!";
      resObject["Deploy status:"] = "Ok";
      resObject["Jobs:"] = await Job.count();
      res.status(200).send(resObject);
    } catch (e) {
      /* istanbul ignore next */
      const logId = await util.logServerError(e, config.user);
      /* istanbul ignore next */
      res.status(500).send({ error: labels.common.debugMessage, logId: logId });
    }
  });
}
