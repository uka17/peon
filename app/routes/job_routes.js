// routes/job_routes.js
let util = require('../tools/util');
let jobEngine = require('../engines/job');
let _ = require('lodash');
const config = require('../../config/config');
const restTemplateSelectAll = require('../../config/rest_templates').restTemplateSelectAll;
const labels = require('../../config/message_labels')('en');
let ver = '/v1.0';

module.exports = function(app) {
  app.get(ver + '/jobs/count', async (req, res) => {
    //get jobs count
    try {
      let result = await jobEngine.getJobCount();
      if(result == null)
        res.status(404).send();
      else {
        let resObject = {};
        resObject[labels.common.count] = result;
        res.status(200).send(resObject);
      }
    }
    catch(e) {      
      /* istanbul ignore next */
      let logId = await util.logServerError(e, config.user);
      /* istanbul ignore next */
      res.status(500).send({error: labels.common.debugMessage, logId: logId});
    }
  });

  app.get(ver + '/jobs', async (req, res) => {
    //get all jobs
    try {
      let filter, sortingExpression, perPage, page;
      if(req.query.sort !== undefined) {
        sortingExpression = req.query.sort.split('|');
        if(sortingExpression.length == 1)
          sortingExpression.push('asc');
      }
      else 
        sortingExpression = ['id', 'asc'];
      
      if(req.query.filter !== undefined)
        filter = req.query.filter;
      else 
        filter = '';
      
      perPage = parseInt(req.query.per_page);
      perPage = isNaN(perPage) ? 10 : perPage;

      page = parseInt(req.query.page);
      page = isNaN(page) ? 1 : page;

      let result = await jobEngine.getJobList(filter, sortingExpression[0], sortingExpression[1], perPage, page);
      if(result == null)
        res.status(404).send();
      else {
        let wrappedResult = JSON.parse(JSON.stringify(restTemplateSelectAll));
        wrappedResult.data = result;
        wrappedResult.pagination.total = 200;
        wrappedResult.pagination.per_page = perPage;
        wrappedResult.pagination.current_page = page;
        wrappedResult.pagination.last_page = 100;
        wrappedResult.pagination.next_page_url = 'mail.ru';
        wrappedResult.pagination.prev_page_url = 'mail.ru';
        wrappedResult.pagination.from = perPage*(page-1) + 1;
        wrappedResult.pagination.to = perPage*page;

        res.status(200).send(wrappedResult);
      }
    }
    catch(e) {      
      /* istanbul ignore next */
      let logId = await util.logServerError(e, config.user);
      /* istanbul ignore next */
      res.status(500).send({error: labels.common.debugMessage, logId: logId});
    }
  });

  app.get(ver + '/jobs/:id', async (req, res) => { 
    //get job by id
    try {
      let result = await jobEngine.getJob(req.params.id);
      if(result == null)
        res.status(404).send();
      else
        res.status(200).send(result);
    }
    catch(e) {      
      /* istanbul ignore next */
      let logId = await util.logServerError(e, config.user);
      /* istanbul ignore next */
      res.status(500).send({error: labels.common.debugMessage, logId: logId});
    }
  });

  app.post(ver + '/jobs', async (req, res) => {
    //create new job
    try {
      const job = req.body;
      let JobAssesmentResult = jobEngine.calculateNextRun(job);
      
      /* istanbul ignore if */
      if(!JobAssesmentResult.isValid)
        res.status(400).send({"requestValidationErrors": JobAssesmentResult.errorList});
      else {
        let result = await jobEngine.createJob(job, config.user);
        await jobEngine.updateJobNextRun(result.id, JobAssesmentResult.nextRun.toUTCString());
        res.status(201).send(result);
      }
    }    
    catch(e) {      
      /* istanbul ignore next */
      let logId = await util.logServerError(e, config.user);
      /* istanbul ignore next */
      res.status(500).send({error: labels.common.debugMessage, logId: logId});
    }
  });

  app.post(ver + '/jobs/:id', (req, res) => {
    res.sendStatus(405);
  });
  
  app.patch(ver + '/jobs/:id', async (req, res) => {
    //update job by id
    try {
      const job = req.body;
      let JobAssesmentResult = jobEngine.calculateNextRun(job);
      
      /* istanbul ignore next */
      if(!JobAssesmentResult.isValid)
        res.status(400).send({"requestValidationErrors": JobAssesmentResult.errorList});
      else {
        job.nextRun = JobAssesmentResult.nextRun;
        let result = await jobEngine.updateJob(req.params.id, job, config.user);
        let resObject = {};
        resObject[labels.common.updated] = result;
        res.status(200).send(resObject);
      }
    }
    /* istanbul ignore next */
    catch(e) {      
      /* istanbul ignore next */
      let logId = await util.logServerError(e, config.user);
      /* istanbul ignore next */
      res.status(500).send({error: labels.common.debugMessage, logId: logId});
    }
  });

  app.delete(ver + '/jobs/:id', async (req, res) => {
    //delete job by _id
    try {
      let result = await jobEngine.deleteJob(req.params.id, config.user);
      let resObject = {};
      resObject[labels.common.deleted] = result;
      res.status(200).send(resObject);
    }
    /* istanbul ignore next */
    catch(e) {      
      /* istanbul ignore next */
      let logId = await util.logServerError(e, config.user);
      /* istanbul ignore next */
      res.status(500).send({error: labels.common.debugMessage, logId: logId});
    }  
  });
};
//TODO
//user handling
//selectors for job list - protect from injection