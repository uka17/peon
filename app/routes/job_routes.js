// routes/job_routes.js
var mongo = require('mongodb');
var murror = require('../tools/murror');
const user = "test";

module.exports = function(app, dbclient) {
  app.get('/jobs/count', (req, res) => {
    //get jobs count
    dbclient.db('peon').collection('job').count({}, function(err, count) {
      if (err) {
        res.status(500).send({error: "Not able to process"});
      } else {        
        res.status(200).send({count: count});
      } 
    });
  });
  app.get('/jobs', (req, res) => {
    //get all jobs
    const where = {  };
    dbclient.db('peon').collection('job').find(where).toArray(function(err, result) {
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
    murror.checkErrorList();
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
      if(!(typeof job.name === "string"))
        murror.addError("Parameter 'name' should be string");
      if(!(typeof job.description === "string"))
        murror.addError("Parameter 'description' should be a string");        
      if(!(typeof job.enabled === "boolean"))
        murror.addError("Parameter 'enabled' should be a boolean");            
      job.createdOn = Date.now();     
      job.createdBy = user;       
      job.modifiedOn = Date.now();    
      job.modifiedBy = user;

      murror.checkErrorList();
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
  app.put('/jobs/:id', (req, res) => {
    //update job by _id
    const where = { '_id': new mongo.ObjectID(req.params.id) };
    const newvalues = req.body;
    newvalues.modifiedOn = Date.now();
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
    res.type('application/json');
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