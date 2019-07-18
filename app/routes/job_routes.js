// routes/job_routes.js
var util = require('../tools/util');
var jobEngine = require('../engines/job');
const config = require('../../config/config');
const labels = require('../../config/message_labels')('en');
var ver = '/v1.0';

module.exports = function(app, dbclient) {
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
      let result = await jobEngine.getJobList();
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
        job.nextRun = JobAssesmentResult.nextRun;
        let result = await jobEngine.createJob(job, config.user);
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