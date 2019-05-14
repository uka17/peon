// routes/job_routes.js
var utools = require('../tools/utools');
var validation = require('../tools/validations');
const config = require('../../config/config');
const messageBox = require('../../config/message_labels');
var schedulator = require('schedulator');
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
          utools.handleServerException(err, config.user, dbclient, res);
        } 
        else {        
          let resObject = {};
          resObject[messageBox.common.count] = result.rows[0].count;
          res.status(200).send(resObject);
        } 
      });  
    }
    catch(e) {
      /* istanbul ignore next */
      utools.handleServerException(e, config.user, dbclient, res);
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
          utools.handleServerException(err, config.user, dbclient, res);
        } else {        
          //TODO Probably need to put try..catch here?
          res.status(200).send(result.rows[0].jobs);
        } 
      });
    }
    catch(e) {
      /* istanbul ignore next */
      utools.handleServerException(e, config.user, dbclient, res);
    }
  });
  app.get(ver + '/jobs/:id', (req, res) => {    
    //get job by id
    try {
      const query = {
        "text": 'SELECT public."fnJob_Select"($1) as job',
        "values": [req.params.id]
      };
      //TODO validation before insert or edit
      dbclient.query(query, (err, result) => {  
        /* istanbul ignore if */
        if (err) {
          utools.handleServerException(err, config.user, dbclient, res);
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
      utools.handleServerException(e, config.user, dbclient, res);
    }
  });
  app.post(ver + '/jobs', (req, res) => {
    //create new job
    try {
      const job = req.body;
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
            jobValidationResult.isValid = {"isValid": true};        
            if(job.schedules) {
              for (let i = 0; i < job.schedules.length; i++) {
                let nextRun = schedulator.nextOccurrence(job.schedules[i]);
                if(nextRun.result == null) {
                  jobValidationResult.isValid = false;
                  jobValidationResult.errorList = nextRun.error;
                  break;
                }
              }
            }
            break;
          case 'notifications':
            //TODO validation for notification
            //jobValidationResult = validation.validateStepList(job.steps)
            break;            
        }
        if(!jobValidationResult.isValid)
          break;
      }

      if(!jobValidationResult.isValid)
        res.status(400).send({"requestValidationErrors": jobValidationResult.errorList});
      else {
        const query = {
          "text": 'SELECT public."fnJob_Insert"($1, $2) as id',
          "values": [job, config.user]
        };
        dbclient.query(query, (err, result) => {           
          /* istanbul ignore if */
          if (err) { 
            utools.handleServerException(err, config.user, dbclient, res);
          } else {
            job.id = result.rows[0].id;
            res.status(201).send(job);
          }
        });
      }
    }
    catch(e) {
      /* istanbul ignore next */
      utools.handleServerException(e, config.user, dbclient, res);
    }
  });

  app.post(ver + '/jobs/:id', (req, res) => {
    res.sendStatus(405);
  });
  
  app.patch(ver + '/jobs/:id', (req, res) => {
    //update job by id
    try {
      const query = {
        "text": 'SELECT public."fnJob_Update"($1, $2, $3) as count',
        "values": [req.params.id, req.body, config.user]
      };
      dbclient.query(query, (err, result) => {     
        /* istanbul ignore if */
        if (err) {
          utools.handleServerException(err, config.user, dbclient, res);
        } else {
          let resObject = {};
          resObject[messageBox.common.updated] = result.rows[0].count;
          res.status(200).send(resObject);
        } 
      });
    }
    catch(e) {
      /* istanbul ignore next */
      utools.handleServerException(e, config.user, dbclient, res);
    }
  });
  app.delete(ver + '/jobs/:id', (req, res) => {
    //delete job by _id
    try {
      const query = {
        "text": 'SELECT public."fnJob_Delete"($1) as count',
        "values": [req.params.id]
      };
      //TODO validation before insert or edit
      dbclient.query(query, (err, result) => {  
        /* istanbul ignore if */
        if (err) {
          utools.handleServerException(err, config.user, dbclient, res);
        } else {
          let resObject = {};
          resObject[messageBox.common.deleted] = result.rows[0].count;
          res.status(200).send(resObject);          
        } 
      });
    }
    catch(e) {
      /* istanbul ignore next */
      utools.handleServerException(e, config.user, dbclient, res);
    }
  });    
};
//TODO
//user handling
//selectors for job list - protect from injection