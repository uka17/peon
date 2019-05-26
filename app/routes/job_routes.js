// routes/job_routes.js
var utools = require('../tools/utools')
var validation = require('../tools/validations')
const config = require('../../config/config')
const messageBox = require('../../config/message_labels');
var schedulator = require('schedulator');
var ver = '/v1.0';

/**
 * Validates jib and calculates its next run date and time
 * @param {object} job Job which should be used for calculation
 * @return {object} {isValid: boolean, errorList(optional): string, nextRun(optional): date-time}
 */
function calculateJobNextRun(job) {
  let validationSequence = ['job', 'steps', 'notifications', 'schedules'];
  let jobValidationResult;
  for(i=0; i < validationSequence.length; i++) {        
    switch(validationSequence[i]) {
      case 'job':
        jobValidationResult = validation.validateJob(job);     
        break;
      case 'steps':
        jobValidationResult = validation.validateStepList(job.steps)
        break;
      case 'notifications':
        //TODO validation for notification
        //jobValidationResult = validation.validateStepList(job.steps)
        break;                 
      case 'schedules':  
        let nextRunList = [];        
        if(job.schedules) {
          for (let i = 0; i < job.schedules.length; i++) {
            if(job.schedules[i].enabled || !job.schedules[i].hasOwnProperty("enabled")) {
              let nextRun = schedulator.nextOccurrence(job.schedules[i]);
              if(nextRun.result != null)
                nextRunList.push(nextRun.result);
              else
                if(nextRun.error.includes("schema is incorrect")) 
                  return {"isValid": false, "errorList": `schedule[${i}] ${nextRun.error}`};
            }
          }
        }
        if(nextRunList.length == 0)
          return {"isValid": false, "errorList": messageBox.schedule.nextRunCanNotBeCalculated};
        else
          jobValidationResult = {"isValid": true, "nextRun": utools.getMinDateTime(nextRunList)};
        break;   
    }
    if(!jobValidationResult.isValid)
      return jobValidationResult;
  }
  return jobValidationResult;
}

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
      let JobAssesmentResult = calculateJobNextRun(job);
      if(!JobAssesmentResult.isValid)
        res.status(400).send({"requestValidationErrors": JobAssesmentResult.errorList});
      else {
        console.log(JobAssesmentResult.nextRun.toUTCString());
        const query = {
          "text": 'SELECT public."fnJob_Insert"($1, $2, $3) as id',
          "values": [job, JobAssesmentResult.nextRun.toUTCString(), config.user]
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
      const job = req.body;
      let JobAssesmentResult = calculateJobNextRun(job);

      if(!JobAssesmentResult.isValid)
        res.status(400).send({"requestValidationErrors": JobAssesmentResult.errorList});
      else {
        const query = {
          "text": 'SELECT public."fnJob_Update"($1, $2, $3, $4) as count',
          "values": [req.params.id, job, JobAssesmentResult.nextRun.toUTCString(), config.user]
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