// routes/job_routes.js
var mongo = require('mongodb');
var utools = require('../tools/utools');
const user = "test";

module.exports = function(app, dbclient) {
  app.get('/jobs/count', (req, res) => {
    //get jobs count
    dbclient.db('peon').collection('job').count(req.body, function(err, count) {
      if (err) {
        res.status(500).send({error: "Not able to process"});
      } else {        
        res.status(200).send({count: count});
      } 
    });
  });
  app.get('/jobs', (req, res) => {
    //get all jobs
    dbclient.db('peon').collection('job').find(req.body).toArray(function(err, result) {
      if (err) {
        res.status(500).send({error: "Not able to process"});
      } else {        
        res.status(200).send(result);
      } 
    });
  });
  app.get('/jobs/:id', (req, res) => {    
    //get job by id
    const where = { '_id': new mongo.ObjectID(req.params.id) };
    utools.checkErrorList();
    dbclient.db('peon').collection('job').findOne(where, (err, item) => {
      if (err) {
        res.status(500).send({error: "Not able to process"});
      } else {
        res.status(200).send(item);
      } 
    });
  });
  app.post('/jobs', (req, res) => {
    //create new job
    try {
      const job = req.body;
      if(!(typeof job.name === "string") && job.name !== undefined)
        utools.addError("Parameter 'name' should be string");
      if(!(typeof job.description === "string") && job.name !== undefined)
        utools.addError("Parameter 'description' should be a string");        
      if(!(typeof job.enabled === "boolean") && job.name !== undefined)
        utools.addError("Parameter 'enabled' should be a boolean");            
      job.createdOn = utools.getTimestamp();     
      job.createdBy = user;       
      job.modifiedOn = utools.getTimestamp();    
      job.modifiedBy = user;

      utools.checkErrorList();
      dbclient.db('peon').collection('job').insert(job, (err, result) => {
        if (err) { 
          res.status(500).send({error: err});
        } else {
          res.status(201).send(result.ops[0]);
        }
      });
    }
    catch(e) {
      res.status(500).send({error: e.message });
    }
  });
  app.post('/jobs/:id', (req, res) => {
    res.sendStatus(405);
  });
  app.patch('/jobs/:id', (req, res) => {
    //update job by id
    const job = req.body;
    const where = { '_id': new mongo.ObjectID(req.params.id) };
    const newvalues = req.body;
    if(!(typeof job.name === "string") && job.name !== undefined)
      utools.addError("Parameter 'name' should be a string");
    if(!(typeof job.description === "string") && job.name !== undefined)
      utools.addError("Parameter 'description' should be a string");        
    if(!(typeof job.enabled === "boolean") && job.name !== undefined)
      utools.addError("Parameter 'enabled' should be a boolean");           

    utools.checkErrorList();  
    newvalues.modifiedOn = utools.getTimestamp();
    newvalues.modifiedBy = user;
    const update = { $set: newvalues};

    dbclient.db('peon').collection('job').updateOne(where, update, (err, result) => {
      if (err) {
        res.status(500).send({error: "Not able to process"});
      } else {
        res.status(200).send({itemsUpdated: result.result.n})
      } 
    });
  });
  app.delete('/jobs/:id', (req, res) => {
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
//user handling
//return multiple errors
//selectors for job list - protect from injection