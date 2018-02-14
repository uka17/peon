// routes/step_routes.js
var mongo = require('mongodb');
var utools = require('../tools/utools');
const user = "test";

module.exports = function(app, dbclient) {
  app.get('/jobs/:id/steps/count', (req, res) => {
    //get jobs steps count
    try {
      const where = { '_id': new mongo.ObjectID(req.params.id) };
      dbclient.db('peon').collection('job').aggregate([{$match: where}, {$project: {count: { $size: "$steps"}}}]).toArray((err, result) => {
        if (err) {
          utools.log(err, 'error', user, dbclient, res);
        } else {        
          res.status(200).json({count: result[0].count});
        } 
      });
    }
    catch(e) {
      if(e.name === 'userError')
        res.status(500).send({error: e.message});
      else
        utools.log(e.message, 'error', user, dbclient, res);
    }
  });
  app.get('/jobs/:id/steps', (req, res) => {
    //get steps list by job id
    try {
      const where = { '_id': new mongo.ObjectID(req.params.id) };
      dbclient.db('peon').collection('job').findOne(where, (err, result) => {
        if (err) {
          utools.log(err, 'error', user, dbclient, res);
        } else {        
          res.status(200).send(result.steps);
        } 
      });
    }
    catch(e) {
      if(e.name === 'userError')
        res.status(500).send({error: e.message});
      else
        utools.log(e.message, 'error', user, dbclient, res);
    }
  });
  app.get('/jobs/:id/steps/:stepId', (req, res) => {    
    try {
      //get step by stepId and by id of job
      const where = { '_id': new mongo.ObjectID(req.params.id) };
      dbclient.db('peon').collection('job').findOne(where, (err, item) => {
        if (err) {
          utools.log(err, 'error', user, dbclient, res);
        } else {
          if(item !== null) {
            if(item.steps !== undefined) {
              const step = item.steps.find((istep) => {return istep._id.toString() === req.params.stepId});
              if(step === undefined)
                res.status(404).send({error: "No step found for mentioned jobId and stepId"});
              else
                res.status(200).send(step);
            }
            else
              res.status(404).send({error: "No steps found for this job"});  
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
        utools.log(e.message, 'error', user, dbclient, res);
    }
  });
  app.post('/jobs/:id/steps', (req, res) => {
    //create new step for a job
    try {
      const step = req.body;
      if(!(typeof step.name === "string") && step.name !== undefined)
        utools.addUserError("Parameter 'name' should be a string");
      if(!(typeof step.command === "string") && step.name !== undefined)
        utools.addUserError("Parameter 'command' should be a string");        
      if(!(typeof step.enabled === "boolean") && step.name !== undefined)
        utools.addUserError("Parameter 'enabled' should be a boolean");            
      step.createdOn = utools.getTimestamp();     
      step.createdBy = user;       
      step.modifiedOn = utools.getTimestamp();    
      step.modifiedBy = user;
      step._id = new mongo.ObjectID();

      const where = { '_id': new mongo.ObjectID(req.params.id) };
      const update = { $addToSet: {steps: step}};

      utools.checkUserErrorList();
      dbclient.db('peon').collection('job').updateOne(where, update, (err, result) => {
        if (err) {
          utools.log(err, 'error', user, dbclient, res);
        } else {
          res.status(201).json({itemsUpdated: result.result.n})
        } 
      });
    }
    catch(e) {
      if(e.name === 'userError')
        res.status(500).send({error: e.message});
      else
        utools.log(e.message, 'error', user, dbclient, res);
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
      step.modifiedBy = user;
      
      //Rename all properties like: name => steps.$.name
      for (var property in step) {
        step = utools.renameProperty(step, property, 'steps.$.' +  property);
      };
      
      //Find step inside the job
      const where = { '_id': new mongo.ObjectID(req.params.id), 'steps._id':  new mongo.ObjectID(req.params.stepId)};      
      const update = { $set: step};

      utools.checkUserErrorList();
      dbclient.db('peon').collection('job').updateOne(where, update, (err, result) => {
        if (err) {
          utools.log(err, 'error', user, dbclient, res);
        } else {
          res.status(200).send({itemsUpdated: result.result.n})
        } 
      });
    }
    catch(e) {
      if(e.name === 'userError')
        res.status(500).send({error: e.message});
      else
        utools.log(e.message, 'error', user, dbclient, res);
    }
  });
  app.delete('/jobs/:id/steps/:stepId', (req, res) => {
    //delete job by _id
    try {
      const where = { '_id': new mongo.ObjectID(req.params.id) };
      const update = { $pull: {'steps': {'_id': new mongo.ObjectID(req.params.stepId)}}};

      dbclient.db('peon').collection('job').updateOne(where, update, (err, result) => {
        if (err) {
          utools.log(err, 'error', user, dbclient, res);
        } else {
          res.status(200).send({itemsDeleted: result.result.n})
        } 
      });
    }
    catch(e) {
      if(e.name === 'userError')
        res.status(500).send({error: e.message});
      else
        utools.log(e.message, 'error', user, dbclient, res);
    }
  });  
};
//TODO
//user handling
//add check for job and step existing