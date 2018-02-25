// routes/job_routes.js
var mongo = require('mongodb');
var utools = require('../tools/utools');
var models = require('../models/job');
const user = "test";

module.exports = function(app, dbclient) {
  app.get('/jobs/count', (req, res) => {
    //get jobs count
    try {
      dbclient.db('peon').collection('job').count(req.body, function(err, count) {
        if (err) {        
          utools.handleException({message: err}, 'error', user, dbclient, res);
        } else {        
          res.status(200).send({count: count});
        } 
      });
    }
    catch(e) {
      utools.handleException(e, 'error', user, dbclient, res);
    }
  });
  app.get('/jobs', (req, res) => {
    //get all jobs
    try {
      dbclient.db('peon').collection('job').find(req.body).toArray(function(err, result) {
        if (err) {
          utools.handleException({message: err}, 'error', user, dbclient, res);
        } else {        
          res.status(200).send(result);
        } 
      });
    }
    catch(e) {
      utools.handleException(e, 'error', user, dbclient, res);
    }
  });
  app.get('/jobs/:id', (req, res) => {    
    //get job by id
    try {
      const where = { '_id': new mongo.ObjectID(req.params.id) };
      dbclient.db('peon').collection('job').findOne(where, (err, item) => {
        if (err) {
          utools.handleException({message: err}, 'error', user, dbclient, res);
        } else {
          res.status(200).send(item);
        } 
      });
    }
    catch(e) {
      utools.handleException(e, 'error', user, dbclient, res);
    }
  });
  app.post('/jobs', (req, res) => {
    //create new job
    try {
      const job = req.body;
      utools.checkObject(job, models.jobSchema);
      job.createdOn = utools.getTimestamp();     
      job.createdBy = user;       
      job.modifiedOn = utools.getTimestamp();    
      job.modifiedBy = user;

      dbclient.db('peon').collection('job').insert(job, (err, result) => {
        if (err) { 
          utools.handleException({message: err}, 'error', user, dbclient, res);
        } else {
          res.status(201).send(result.ops[0]);
        }
      });
    }
    catch(e) {
      utools.handleException(e, 'error', user, dbclient, res);
    }
  });

  app.post('/jobs/:id', (req, res) => {
    res.sendStatus(405);
  });
  
  app.patch('/jobs/:id', (req, res) => {
    //update job by id
    try {
      var job = req.body;      
      utools.checkObject(job, models.jobSchema);
      job.modifiedOn = utools.getTimestamp();
      job.modifiedBy = user;      

      const where = { '_id': new mongo.ObjectID(req.params.id) };      
      const update = { $set: job};

      dbclient.db('peon').collection('job').updateOne(where, update, (err, result) => {
        if (err) {
          utools.handleException({message: err}, 'error', user, dbclient, res);
        } else {
          res.status(200).send({itemsUpdated: result.result.n})
        } 
      });
    }
    catch(e) {
      utools.handleException(e, 'error', user, dbclient, res);
    }
  });
  app.delete('/jobs/:id', (req, res) => {
    //delete job by _id
    try {
      const where = { '_id': new mongo.ObjectID(req.params.id) };
      dbclient.db('peon').collection('job').deleteOne(where, (err, result) => {
        if (err) {
          utools.handleException({message: err}, 'error', user, dbclient, res);
        } else {
          res.status(200).send({itemsDeleted: result.result.n})
        } 
      });
    }
    catch(e) {
      utools.handleException(e, 'error', user, dbclient, res);
    }
  });    
};
//TODO
//user handling
//selectors for job list - protect from injection