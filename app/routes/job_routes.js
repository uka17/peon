// routes/job_routes.js
var util = require('../tools/util')
var jobEngine = require('../engines/job');
const config = require('../../config/config')
const labels = require('../../config/message_labels')('en');
var ver = '/v1.0';

module.exports = function(app, dbclient) {
  app.get(ver + '/jobs/count', (req, res) => {
    //get jobs count
    try {
      const query = {
        "text": 'SELECT public."fnJob_Count"() as count'
      };
      dbclient.query(query, (err, result) => {
        /* istanbul ignore if */
        if (err) {        
          util.handleServerException(err, config.user, dbclient, res);
        } 
        else {        
          let resObject = {};
          resObject[labels.common.count] = result.rows[0].count;
          res.status(200).send(resObject);
        } 
      });  
    }
    catch(e) {
      /* istanbul ignore next */
      util.handleServerException(e, config.user, dbclient, res);
    }
  });
  app.get(ver + '/jobs', (req, res) => {
    //get all jobs
    try {
      const query = {
        "text": 'SELECT public."fnJob_SelectAll"() as jobs'
      };
      //TODO validation before insert or edit
      dbclient.query(query, (err, result) => {          
        /* istanbul ignore if */
        if (err) {
          util.handleServerException(err, config.user, dbclient, res);
        } else {        
          //TODO Probably need to put try..catch here?
          res.status(200).send(result.rows[0].jobs);
        } 
      });
    }
    catch(e) {
      /* istanbul ignore next */
      util.handleServerException(e, config.user, dbclient, res);
    }
  });
  app.get(ver + '/jobs/:id', (req, res) => {    
    //get job by id
    try {
      const query = {
        "text": 'SELECT public."fnJob_Select"($1) as job',
        "values": [req.params.id]
      };
      dbclient.query(query, (err, result) => {  
        /* istanbul ignore if */
        if (err) {
          util.handleServerException(err, config.user, dbclient, res);
        } else {
          if(result.rows[0].job == null)
            res.status(404).send();
          else
            res.status(200).send(result.rows[0].job);
        } 
      });
    }
    catch(e) {
      /* istanbul ignore next */
      util.handleServerException(e, config.user, dbclient, res);
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
      let logId = await util.logServerError(e);
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
      let logId = await util.logServerError(e);
      /* istanbul ignore next */
      res.status(500).send({error: labels.common.debugMessage, logId: logId});
    }
  });

  app.delete(ver + '/jobs/:id', (req, res) => {
    //delete job by _id
    try {
      let result = await jobEngine.deleteJobJob(req.params.id, config.user);
      let resObject = {};
      resObject[labels.common.deleted] = result;
      res.status(200).send(resObject);
    }
    /* istanbul ignore next */
    catch(e) {      
      /* istanbul ignore next */
      let logId = await util.logServerError(e);
      /* istanbul ignore next */
      res.status(500).send({error: labels.common.debugMessage, logId: logId});
    }  
  });
};
//TODO
//user handling
//selectors for job list - protect from injection