// routes/schedule_routes.js
var mongo = require('mongodb');
var utools = require('../tools/utools');
const config = require('../../config/config');

module.exports = function(app, dbclient) {
  app.get('/jobs/:id/schedules/count', (req, res) => {
    //get jobs schedules count
    try {
      const where = { '_id': new mongo.ObjectID(req.params.id) };
      dbclient.db(config.db_name).collection('job').aggregate([{$match: where}, {$project: {count: { $size: "$schedules"}}}]).toArray((err, result) => {
        if (err) {
          utools.log(err, 'error',config.user, dbclient, res);
        } else {        
          res.status(200).json({count: result[0].count});
        } 
      });
    }
    catch(e) {
      if(e.name === 'userError')
        res.status(500).send({error: e.message});
      else
        utools.log(e.message, 'error',config.user, dbclient, res);
    }
  });
  app.get('/jobs/:id/schedules', (req, res) => {
    //get schedules list by job id
    try {
      const where = { '_id': new mongo.ObjectID(req.params.id) };
      dbclient.db(config.db_name).collection('job').findOne(where, (err, result) => {
        if (err) {
          utools.log(err, 'error',config.user, dbclient, res);
        } else {        
          res.status(200).send(result.schedules);
        } 
      });
    }
    catch(e) {
      if(e.name === 'userError')
        res.status(500).send({error: e.message});
      else
        utools.log(e.message, 'error',config.user, dbclient, res);
    }
  });
  app.get('/jobs/:id/schedules/:scheduleId', (req, res) => {    
    try {
      //get schedule by scheduleId and by id of job
      const where = { '_id': new mongo.ObjectID(req.params.id) };
      dbclient.db(config.db_name).collection('job').findOne(where, (err, item) => {
        if (err) {
          utools.log(err, 'error',config.user, dbclient, res);
        } else {
          if(item !== null) {
            if(item.schedules !== undefined) {
              const schedule = item.schedules.find((ischedule) => {return ischedule._id.toString() === req.params.stepId});
              if(schedule === undefined)
                res.status(404).send({error: "No schedule found for mentioned jobId and scheduleId"});
              else
                res.status(200).send(schedule);
            }
            else
              res.status(404).send({error: "No schedule found for this job"});  
          }
          else
            res.status(404).send({error: "Job not found"});
        } 
      });
    }
    catch(e) {
      if(e.name === 'userError')
        res.status(500).send({error: e.message});
      else
        utools.log(e.message, 'error',config.user, dbclient, res);
    }
  });
  app.post('/jobs/:id/schedules', (req, res) => {
    //create new schedule for a job
    try {
      const step = req.body;
      if(!(typeof step.name === "string") && step.name !== undefined)
        utools.addUserError("Parameter 'name' should be a string");
      if(!(typeof step.command === "string") && step.name !== undefined)
        utools.addUserError("Parameter 'command' should be a string");        
      if(!(typeof step.enabled === "boolean") && step.name !== undefined)
        utools.addUserError("Parameter 'enabled' should be a boolean");            
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
          utools.log(err, 'error',config.user, dbclient, res);
        } else {
          res.status(201).json({itemsUpdated: result.result.n})
        } 
      });
    }
    catch(e) {
      if(e.name === 'userError')
        res.status(500).send({error: e.message});
      else
        utools.log(e.message, 'error',config.user, dbclient, res);
    }
  });
  app.patch('/jobs/:id/steps/:stepId', (req, res) => {
    //updates step by stepId in job get by id
    try {
      var step = req.body;
      if(!(typeof step.name === "string") && step.name !== undefined)
        utools.addUserError("Parameter 'name' should be a string");
      if(!(typeof step.command === "string") && step.command !== undefined)
        utools.addUserError("Parameter 'command' should be a string");        
      if(!(typeof step.enabled === "boolean") && step.enabled !== undefined)
        utools.addUserError("Parameter 'enabled' should be a boolean");            
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
          utools.log(err, 'error',config.user, dbclient, res);
        } else {
          res.status(200).send({itemsUpdated: result.result.n})
        } 
      });
    }
    catch(e) {
      if(e.name === 'userError')
        res.status(500).send({error: e.message});
      else
        utools.log(e.message, 'error',config.user, dbclient, res);
    }
  });
  app.delete('/jobs/:id/steps/:stepId', (req, res) => {
    //delete job by _id
    try {
      const where = { '_id': new mongo.ObjectID(req.params.id) };
      const update = { $pull: {'steps': {'_id': new mongo.ObjectID(req.params.stepId)}}};

      dbclient.db(config.db_name).collection('job').updateOne(where, update, (err, result) => {
        if (err) {
          utools.log(err, 'error',config.user, dbclient, res);
        } else {
          res.status(200).send({itemsDeleted: result.result.n})
        } 
      });
    }
    catch(e) {
      if(e.name === 'userError')
        res.status(500).send({error: e.message});
      else
        utools.log(e.message, 'error',config.user, dbclient, res);
    }
  });  
};
//TODO
//user handling
//add check for job and step existing