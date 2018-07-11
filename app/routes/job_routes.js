// routes/job_routes.js
var mongo = require('mongodb');
var utools = require('../tools/utools');
var validation = require('../tools/validation');
var models = require('../models/app_models');
const config = require('../../config/config');
const messageBox = require('../../config/message_labels');

module.exports = function(app, dbclient) {
  app.get('/jobs/count', (req, res) => {
    //get jobs count
    try {
      dbclient.db(config.db_name).collection('job').count(req.body, function(err, count) {
        if (err) {        
          utools.handleServerException(err, config.user, dbclient, res);
        } 
        else {        
          let resObject = {};
          resObject[messageBox.common.count] = count;
          res.status(200).send(resObject);
        } 
      });
    }
    catch(e) {
      utools.handleServerException(e, config.user, dbclient, res);
    }
  });
  app.get('/jobs', (req, res) => {
    //get all jobs
    try {
      dbclient.db(config.db_name).collection('job').find(req.body).toArray(function(err, result) {
        if (err) {
          utools.handleServerException(err, config.user, dbclient, res);
        } else {        
          res.status(200).send(result);
        } 
      });
    }
    catch(e) {
      utools.handleServerException(e, config.user, dbclient, res);
    }
  });
  app.get('/jobs/:id', (req, res) => {    
    //get job by id
    try {
      const where = { '_id': new mongo.ObjectID(req.params.id) };
      dbclient.db(config.db_name).collection('job').findOne(where, (err, item) => {
        if (err) {
          utools.handleServerException(err, config.user, dbclient, res);
        } else {
          res.status(200).send(item);
        } 
      });
    }
    catch(e) {
      utools.handleServerException(e, config.user, dbclient, res);
    }
  });
  app.post('/jobs', (req, res) => {
    //create new job
    try {
      const job = req.body;
      //job body validationc
      let validationSequence = ['job', 'steps', 'schedules', 'notifications'];
      let jobValidationResult;
      for(i=0; i < validationSequence.length; i++) {        
        switch(validationSequence[i]) {
          case 'job':
            jobValidationResult = validation.validateJob(job);     
            break;
          case 'steps':
            jobValidationResult = validation.validateStepList(job.steps)
            break;
          case 'schedules':
            jobValidationResult = validation.validateScheduleList(job.schedules)
            break;
          case 'notifications':
            //jobValidationResult = validation.validateStepList(job.steps)
            break;            
        }
        if(!jobValidationResult.isValid)
          break;
      }

      if(!jobValidationResult.isValid)
        res.status(400).send({requestValidationErrors: jobValidationResult.errors});
      else {
        job.createdOn = utools.getTimestamp();     
        job.createdBy = config.user;       
        job.modifiedOn = utools.getTimestamp();    
        job.modifiedBy = config.user;

        dbclient.db(config.db_name).collection('job').insert(job, (err, result) => {
          if (err) { 
            utools.handleServerException(err, config.user, dbclient, res);
          } else {
            res.status(201).send(result.ops[0]);
          }
        });
      }
    }
    catch(e) {
      utools.handleServerException(e, config.user, dbclient, res);
    }
  });

  app.post('/jobs/:id', (req, res) => {
    res.sendStatus(405);
  });
  
  app.patch('/jobs/:id', (req, res) => {
    //update job by id
    try {
      var job = req.body;      
      job.modifiedOn = utools.getTimestamp();
      job.modifiedBy = config.user;      

      const where = { '_id': new mongo.ObjectID(req.params.id) };      
      const update = { $set: job};

      dbclient.db(config.db_name).collection('job').updateOne(where, update, (err, result) => {
        if (err) {
          utools.handleServerException(err, config.user, dbclient, res);
        } else {
          let resObject = {};
          resObject[messageBox.common.updated] = result.result.n;
          res.status(200).send(resObject);
        } 
      });
    }
    catch(e) {
      utools.handleServerException(e, config.user, dbclient, res);
    }
  });
  app.delete('/jobs/:id', (req, res) => {
    //delete job by _id
    try {
      const where = { '_id': new mongo.ObjectID(req.params.id) };
      dbclient.db(config.db_name).collection('job').deleteOne(where, (err, result) => {
        if (err) {
          utools.handleServerException(err, config.user, dbclient, res);
        } else {
          let resObject = {};
          resObject[messageBox.common.deleted] = result.result.n;
          res.status(200).send(resObject);          
        } 
      });
    }
    catch(e) {
      utools.handleServerException(e, config.user, dbclient, res);
    }
  });    
};
//TODO
//user handling
//selectors for job list - protect from injection