// routes/job_routes.js
let util = require('../tools/util');
let jobEngine = require('../engines/job');
const config = require('../../config/config');
const restConfig = require('../../config/rest_config');
const labels = require('../../config/message_labels')('en');
let ver = '/v1.0';

module.exports = function(app) {
  app.get(ver + '/jobs/count', async (req, res) => {
    //get jobs count
    try {
      let filter;

      if(req.query.filter !== undefined)
        filter = req.query.filter;
      else 
        filter = '';      

      let result = await jobEngine.getJobCount(filter);
      /* istanbul ignore if */
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
      
      perPage = util.isNumber(req.query.per_page, restConfig.defaultPerPage);
      page = util.isNumber(req.query.page, 1);

      let result = await jobEngine.getJobList(filter, sortingExpression[0], sortingExpression[1], perPage, page);
      /* istanbul ignore if */
      if(result == null)
        res.status(404).send();
      else {
        let wrappedResult = JSON.parse(JSON.stringify(restConfig.templates.selectAll));
        let jobCount = await jobEngine.getJobCount(filter);
        wrappedResult.data = result;
        let url = `${req.protocol}://${req.get('host')}${req._parsedUrl.pathname}`;
        wrappedResult.pagination = util.pagination(url, perPage, page, jobCount, req.query.filter, req.query.sort);

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
      let jobAssesmentResult = jobEngine.calculateNextRun(job);
      
      /* istanbul ignore if */
      if(!jobAssesmentResult.isValid)
        res.status(400).send({"requestValidationErrors": jobAssesmentResult.errorList});
      else {
        let result = await jobEngine.createJob(job, config.user);
        await jobEngine.updateJobNextRun(result.id, jobAssesmentResult.nextRun.toUTCString(), config.user);
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
      let jobAssesmentResult = jobEngine.calculateNextRun(job);
      
      /* istanbul ignore next */
      if(!jobAssesmentResult.isValid)
        res.status(400).send({"requestValidationErrors": jobAssesmentResult.errorList});
      else {
        job.nextRun = jobAssesmentResult.nextRun;
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