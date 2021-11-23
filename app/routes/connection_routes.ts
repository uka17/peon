// routes/connection_routes.js
import Validation from "../tools/validation";
import Connection from "../classes/connection";
import restConfig from "../../config/rest_config";
import config from "../../config/config";
import * as util from "../tools/util";
import message_labels from "../../config/message_labels";
const labels = message_labels("en");
import express from "express";
import ConnectionBody from "../classes/connectionBody";
import ver from "../../config/api_version";

//TODO here and everywhere - change to export default
export default function (app: express.Application) {
  app.get(
    ver + "/connections/count",
    async (req: express.Request, res: express.Response) => {
      //get connection count
      try {
        let filter: string;
        if (req.query.filter !== undefined) filter = req.query.filter as string;
        else filter = "";

        const result = await Connection.count(filter);
        /* istanbul ignore if */
        if (result == null) res.status(404).send();
        else {
          const resObject: Record<string, unknown> = {};
          resObject[labels.common.count] = result;
          res.status(200).send(resObject);
        }
      } catch (e) {
        /* istanbul ignore next */
        const logId: number = await util.logServerError(e, config.user);
        /* istanbul ignore next */
        res
          .status(500)
          .send({ error: labels.common.debugMessage, logId: logId });
      }
    }
  );

  app.get(
    ver + "/connections",
    async (req: express.Request, res: express.Response) => {
      //get all connections
      try {
        let filter: string, sortingExpression: Array<string>;

        if (req.query.sort !== undefined) {
          sortingExpression = (req.query.sort as string).split("|");
          if (sortingExpression.length == 1) sortingExpression.push("asc");
        } else sortingExpression = ["id", "asc"];

        if (req.query.filter !== undefined) filter = req.query.filter as string;
        else filter = "";

        const perPage: number = util.isNumber(
          req.query.per_page,
          restConfig.defaultPerPage
        ) as number;
        const page: number = util.isNumber(req.query.page, 1);

        const result: unknown = await Connection.list(
          filter,
          sortingExpression[0],
          sortingExpression[1] as string,
          perPage,
          page
        );
        /* istanbul ignore if */
        if (result == null) res.status(204).send();
        else {
          const wrappedResult = JSON.parse(
            JSON.stringify(restConfig.templates.selectAll)
          );
          const connectionCount: number = (await Connection.count(
            filter
          )) as number;
          wrappedResult.data = result;
          const url = `${req.protocol}://${req.get("host")}${req.path}`;
          wrappedResult.pagination = util.pagination(
            url,
            perPage,
            page,
            connectionCount,
            req.query.filter as string,
            req.query.sort as string
          );

          res.status(200).send(wrappedResult);
        }
      } catch (e) {
        /* istanbul ignore next */
        const logId: number = await util.logServerError(e, config.user);
        /* istanbul ignore next */
        res
          .status(500)
          .send({ error: labels.common.debugMessage, logId: logId });
      }
    }
  );

  app.get(
    ver + "/connections/:id",
    async (req: express.Request, res: express.Response) => {
      //get connection by id
      try {
        const result: unknown = await Connection.get(
          req.params.id as unknown as number
        );
        if (result == null) res.status(404).send();
        else res.status(200).send(result);
      } catch (e) {
        /* istanbul ignore next */
        const logId: number = await util.logServerError(e, config.user);
        /* istanbul ignore next */
        res
          .status(500)
          .send({ error: labels.common.debugMessage, logId: logId });
      }
    }
  );

  app.post(
    ver + "/connections",
    async (req: express.Request, res: express.Response) => {
      //create new connection
      try {
        const body: ConnectionBody = req.body;
        const connectionValidationResult = Validation.validateConnection(body);
        if (!connectionValidationResult.isValid)
          res.status(400).send({
            "requestValidationErrors": connectionValidationResult.errorList,
          });
        else {
          const connection = await new Connection(body);
          const savedConnection: Connection = (await connection.save(
            config.user
          )) as Connection;
          res.status(201).send(savedConnection);
        }
      } catch (e) {
        /* istanbul ignore next */
        const logId = await util.logServerError(e, config.user);
        /* istanbul ignore next */
        res
          .status(500)
          .send({ error: labels.common.debugMessage, logId: logId });
      }
    }
  );

  app.post(ver + "/connections/:id", (req, res) => {
    res.sendStatus(405);
  });

  app.patch(ver + "/connections/:id", async (req, res) => {
    //update connection by id
    try {
      const newBody: ConnectionBody = req.body;
      const connectionValidationResult = Validation.validateConnection(newBody);

      /* istanbul ignore if */
      if (!connectionValidationResult.isValid)
        res.status(400).send({
          "requestValidationErrors": connectionValidationResult.errorList,
        });
      else {
        const connection: Connection = new Connection(newBody);
        //TODO add check for INT incorrect parse
        connection.id = parseInt(req.params.id);
        if (isNaN(connection.id))
          throw TypeError(`Provided ID is not a number`);
        const result: unknown = await connection.update(config.user);
        if (typeof result === "number") {
          const resObject = {};
          resObject[labels.common.updated] = result;
          res.status(200).send(resObject);
        } else throw Error(`Update for id ${req.params.id} failed`);
      }
    } catch (e) {
      /* istanbul ignore next */
      /* istanbul ignore next */
      const logId = await util.logServerError(e, config.user);
      /* istanbul ignore next */
      res.status(500).send({ error: labels.common.debugMessage, logId: logId });
    }
  });

  app.delete(ver + "/connections/:id", async (req, res) => {
    //delete connection by _id
    try {
      const connection: Connection = new Connection();
      connection.id = parseInt(req.params.id);
      if (isNaN(connection.id)) throw TypeError(`Provided ID is not a number`);
      const result: unknown = await connection.delete(config.user);
      if (typeof result === "number") {
        const resObject = {};
        resObject[labels.common.deleted] = result;
        res.status(200).send(resObject);
      } else throw Error(`Delete for id ${req.params.id} failed`);
    } catch (e) {
      /* istanbul ignore next */
      /* istanbul ignore next */
      const logId = await util.logServerError(e, config.user);
      /* istanbul ignore next */
      res.status(500).send({ error: labels.common.debugMessage, logId: logId });
    }
  });
}
//TODO
//user handling
//selectors for connection list - protect from injection
