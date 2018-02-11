// routes/step_routes.js
var mongo = require('mongodb');
var utools = require('../tools/utools');
const user = "test";

module.exports = function(app, dbclient) {
  app.get('/jobs/:id/steps/count', (req, res) => {
    //get jobs steps count
    const where = { '_id': new mongo.ObjectID(req.params.id) };
    dbclient.db('peon').collection('job').aggregate([{$match: where}, {$project: {count: { $size: "$steps"}}}]).toArray((err, result) => {
      if (err) {
        res.status(501).send({error: "Not able to process"});
      } else {        
        res.status(200).send({count: result[0].count});
      } 
    });
  });
  app.get('/jobs/:id/steps', (req, res) => {
    //get steps list by job id
    const where = { '_id': new mongo.ObjectID(req.params.id) };
    dbclient.db('peon').collection('job').findOne(where, (err, result) => {
      if (err) {
        res.status(501).send({error: "Not able to process"});
      } else {        
        res.status(200).send(result.steps);
      } 
    });
  });
  app.get('/jobs/:id/steps/:stepId', (req, res) => {    
    //get step by stepId and by id of job
    const where = { '_id': new mongo.ObjectID(req.params.id) };
    utools.checkErrorList();
    dbclient.db('peon').collection('job').findOne(where, (err, item) => {
      if (err) {
        res.status(500).send({error: "Not able to process"});
      } else {
        const step = item.steps.find((step) => {return step._id.toString() === req.params.stepId});
        if(step === undefined)
          res.status(500).send({error: "Not able to process"});
        else
          res.status(200).send(step);
      } 
    });
  });
  app.post('/jobs/:id/steps', (req, res) => {
    //create new step for a job
    try {
      const step = req.body;
      if(!(typeof step.name === "string"))
        utools.addError("Parameter 'name' should be string");
      if(!(typeof step.command === "string"))
        utools.addError("Parameter 'command' should be a string");        
      if(!(typeof step.enabled === "boolean"))
        utools.addError("Parameter 'enabled' should be a boolean");            
      step.createdOn = utools.getTimestamp();     
      step.createdBy = user;       
      step.modifiedOn = utools.getTimestamp();    
      step.modifiedBy = user;
      step._id = new mongo.ObjectID();

      const where = { '_id': new mongo.ObjectID(req.params.id) };
      const update = { $addToSet: {steps: step}};

      utools.checkErrorList();
      dbclient.db('peon').collection('job').updateOne(where, update, (err, result) => {
        if (err) {
          res.status(500).send({error: "Not able to process"});
        } else {
          res.status(200).send({itemsUpdated: result.result.n})
        } 
      });
    }
    catch(e) {
      res.status(500).send({error: e.message });
    }
  });
  app.put('/jobs/:id/steps/:stepId', (req, res) => {
    //updates step by stepId in job get by id
    try {
      const step = req.body;
      if(!(typeof step.name === "string"))
        utools.addError("Parameter 'name' should be string");
      if(!(typeof step.command === "string"))
        utools.addError("Parameter 'command' should be a string");        
      if(!(typeof step.enabled === "boolean") && step.enabled !== undefined)
        utools.addError("Parameter 'enabled' should be a boolean");            
      step.modifiedOn = utools.getTimestamp();    
      step.modifiedBy = user;

      const where = { '_id': new mongo.ObjectID(req.params.id) };
      const update = { $set: {"steps.$[element]": step}};

      utools.checkErrorList();
      dbclient.db('peon').collection('job').updateOne(where, update, {arrayFilters: [ { "elem._id": new mongo.ObjectID(req.params.stepId) } ]}, (err, result) => {
        if (err) {
          res.status(500).send({error: "Not able to process"});
        } else {
          res.status(200).send({itemsUpdated: result.result.n})
        } 
      });
    }
    catch(e) {
      res.status(500).send({error: e.message });
    }
  });
  app.delete('/jobs/:id/steps/:stepId', (req, res) => {
    //delete job by _id
    const where = { '_id': new mongo.ObjectID(req.params.id) };
    dbclient.db('peon').collection('job').deleteOne(where, (err, result) => {
      if (err) {
        res.status(500).send({error: "Not able to process"});
      } else {
        res.status(200).send({itemsDeleted: result.result.n})
      } 
    });
  });  
};
//TODO
//errors handling
//user handling