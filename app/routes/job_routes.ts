import * as util from "../tools/util";
import Job, { IJob } from "../classes/job";
import config from "../../config/config";
import restConfig from "../../config/rest_config";
import message_labels from "../../config/message_labels";
const labels = message_labels("en");
import ver from "../../config/api_version";
import express from "express";

//TODO check parameters comming from user, here and everywhere

export default function (app: express.Application) {
  app.get(
    ver + "/jobs/count",
    async (req: express.Request, res: express.Response) => {
      //get jobs count
      try {
        let filter: string;
        if (req.query.filter !== undefined) filter = req.query.filter as string;
        else filter = "";

        const result = await Job.count(filter);
        /* istanbul ignore if */
        if (result == null) res.status(204).send();
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
    ver + "/jobs",
    async (req: express.Request, res: express.Response) => {
      //get all jobs
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

        const result = await Job.list(
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
          const jobCount: number = (await Job.count(filter)) as number;
          wrappedResult.data = result;
          const url = `${req.protocol}://${req.get("host")}${req.path}`;
          wrappedResult.pagination = util.pagination(
            url,
            perPage,
            page,
            jobCount,
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
    ver + "/jobs/:id",
    async (req: express.Request, res: express.Response) => {
      //get job by id
      try {
        const result = await Job.get(req.params.id as unknown as number);
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
    ver + "/jobs",
    async (req: express.Request, res: express.Response) => {
      //create new job
      try {
        //TODO check if route provided proper body
        const job: Job = new Job({ body: req.body } as IJob);
        job.normalizeStepList();
        // schedule schema will be checked during execution of calculateNextRun()
        const jobAssesmentResult = job.calculateNextRun();

        /* istanbul ignore if */
        if (!jobAssesmentResult.isValid)
          res
            .status(400)
            .send({ "requestValidationErrors": jobAssesmentResult.errorList });
        else {
          const result = (await job.save(config.user)) as Job;
          await result.updateNextRun(jobAssesmentResult.nextRun!.toUTCString());
          const updatedJob = await Job.get(result.id as number);
          res.status(201).send(updatedJob);
        }
      } catch (e) {
        //TODO change error handler to: logAndThrow(res, e, user)
        /* istanbul ignore next */
        const logId: number = await util.logServerError(e, config.user);
        /* istanbul ignore next */
        res
          .status(500)
          .send({ error: labels.common.debugMessage, logId: logId });
      }
    }
  );

  app.post(ver + "/jobs/:id", (req: express.Request, res: express.Response) => {
    res.sendStatus(405);
  });

  app.patch(
    ver + "/jobs/:id",
    async (req: express.Request, res: express.Response) => {
      //update job by id
      try {
        const job: Job = new Job({ body: req.body } as IJob);
        job.id = req.params.id as unknown as number;
        job.normalizeStepList();
        const jobAssesmentResult = job.calculateNextRun();

        /* istanbul ignore next */
        if (!jobAssesmentResult.isValid)
          res
            .status(400)
            .send({ "requestValidationErrors": jobAssesmentResult.errorList });
        else {
          const result = await job.update(config.user);
          job.updateNextRun(jobAssesmentResult.nextRun!.toUTCString());
          const resObject = {};
          resObject[labels.common.updated] = result;
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

  app.delete(
    ver + "/jobs/:id",
    async (req: express.Request, res: express.Response) => {
      //delete job by _id
      try {
        const job: Job = new Job();
        job.id = req.params.id as unknown as number;
        const result = await job.delete(config.user);
        const resObject = {};
        resObject[labels.common.deleted] = result;
        res.status(200).send(resObject);
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
}
//TODO
//user handling
//selectors for job list - protect from injection
