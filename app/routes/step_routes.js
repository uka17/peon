// routes/step_routes.js
var mongo = require('mongodb');
var utools = require('../tools/utools');
var models = require('../models/app_models');
var messageBox = require('../../config/message_labels');
const config = require('../../config/config');

module.exports = function(app, dbclient) {
  app.get('/jobs/:id/steps/count', (req, res) => {
    //get jobs steps count
    try {
      const where = { '_id': new mongo.ObjectID(req.params.id) };
      dbclient.db(config.db_name).collection('job').findOne(where, (err, item) => {
        if (err) {
          utools.handleException({message: err}, 'error',config.user, dbclient, res);
        } else {
          if(item.steps !== undefined)          
            res.status(200).send({count: item.steps.length});
          else
            res.status(200).send({count: 0});
        } 
      });
    }
    catch(e) {
      utools.handleException(e, 'error',config.user, dbclient, res);
    }
  });
  app.get('/jobs/:id/steps', (req, res) => {
    //get steps list by job id
      const where = { '_id': new mongo.ObjectID(req.params.id) };      
      dbclient.db(config.db_name).collection('job').findOne(where, (err, result) => {
        try {
          if (err) {
            utools.handleException({message: err}, 'error',config.user, dbclient, res);
          } else {     
            if(result === null)   
              utools.throwUserError(messageBox.jobNotFound); 
            if(result.steps !== undefined)
              res.status(200).send(result.steps);
            else  
              utools.throwUserError(messageBox.noStepForJob);
          }
        }
        catch(e) {
          utools.handleException(e, 'error',config.user, dbclient, res);
        } 
      });
  });
  app.get('/jobs/:id/steps/:stepId', (req, res) => {    
    
    //get step by stepId and by id of job
    const where = { '_id': new mongo.ObjectID(req.params.id) };
    dbclient.db(config.db_name).collection('job').findOne(where, (err, item) => {
      try {
        if (err) {
          utools.handleException({message: err}, 'error',config.user, dbclient, res);
        } else {
          if(item !== null) {
            if(item.steps !== undefined) {
              const step = item.steps.find((istep) => {return istep._id.toString() === req.params.stepId});
              if(step === undefined) 
                utools.throwUserError(messageBox.noStepForJobAndStep);
              else
                res.status(200).send(step);
            }
            else
              utools.throwUserError(messageBox.noStepForJob);  
          }
          else
            utools.throwUserError(messageBox.jobNotFound);
        }
      }
      catch(e) {
        utools.handleException(e, 'error',config.user, dbclient, res);
      }
    });
  });
  app.post('/jobs/:id/steps', (req, res) => {
    //create new step for a job
    try {
      const step = req.body;
      utools.checkObject(step, models.stepSchema);
      step.createdOn = utools.getTimestamp();     
      step.createdBy =config.user;       
      step.modifiedOn = utools.getTimestamp();    
      step.modifiedBy =config.user;
      step._id = new mongo.ObjectID();

      const where = { '_id': new mongo.ObjectID(req.params.id) };
      const update = { $addToSet: {steps: step}};

      utools.checkUserErrorList();
      dbclient.db(config.db_name).collection('job').updateOne(where, update, (err, result) => {
        if (err) {
          utools.handleException({message: err}, 'error',config.user, dbclient, res);
        } else {
          res.status(201).json({itemsUpdated: result.result.n})
        } 
      });
    }
    catch(e) {
      utools.handleException(e, 'error',config.user, dbclient, res);
    }
  });
  app.patch('/jobs/:id/steps/:stepId', (req, res) => {
    //updates step by stepId in job get by id
    try {
      var step = req.body;
      utools.checkObject(step, models.stepSchema);           
      step.modifiedOn = utools.getTimestamp();    
      step.modifiedBy =config.user;
      
      //Rename all properties like: name => steps.$.name
      for (var property in step) {
        step = utools.renameProperty(step, property, 'steps.$.' +  property);
      };
      
      //Find step inside the job
      const where = { '_id': new mongo.ObjectID(req.params.id), 'steps._id':  new mongo.ObjectID(req.params.stepId)};      
      const update = { $set: step};

      utools.checkUserErrorList();
      dbclient.db(config.db_name).collection('job').updateOne(where, update, (err, result) => {
        if (err) {
          utools.handleException({message: err}, 'error',config.user, dbclient, res);
        } else {
          res.status(200).send({itemsUpdated: result.result.n});
        } 
      });
    }
    catch(e) {
      utools.handleException(e, 'error',config.user, dbclient, res);
    }
  });
  app.delete('/jobs/:id/steps/:stepId', (req, res) => {
    //delete job by _id
    try {
      const where = { '_id': new mongo.ObjectID(req.params.id) };
      const update = { $pull: {'steps': {'_id': new mongo.ObjectID(req.params.stepId)}}};

      dbclient.db(config.db_name).collection('job').updateOne(where, update, (err, result) => {
        if (err) {
          utools.handleException({message: err}, 'error',config.user, dbclient, res);
        } else {
          res.status(200).send({itemsDeleted: result.result.n})
        } 
      });
    }
    catch(e) {
      utools.handleException(e, 'error',config.user, dbclient, res);
    }
  });  
};
//TODO
//user handling