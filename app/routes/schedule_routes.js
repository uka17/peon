// routes/schedule_routes.js
var mongo = require('mongodb');
var utools = require('../tools/utools');
const config = require('../../config/config');
const messageBox = require('../../config/message_labels');

module.exports = function(app, dbclient) {
  app.get('/jobs/:id/schedules/count', (req, res) => {
    //get jobs schedules count
    try {
      const where = { '_id': new mongo.ObjectID(req.params.id) };
      dbclient.db(config.db_name).collection('job').aggregate([{$match: where}, {$project: {count: { $size: "$schedules"}}}]).toArray((err, result) => {
        if (err) {
          utools.handleServerException(err, config.user, dbclient, res);
        } 
        else {        
          let resObject = {};
          resObject[messageBox.common.count] = result[0].count;
          res.status(200).send(resObject);    
        } 
      });
    }
    catch(e) {
      utools.handleServerException(e, config.user, dbclient, res);
    }
  });
  app.get('/jobs/:id/schedules', (req, res) => {
    //get schedules list by job id
    try {
      const where = { '_id': new mongo.ObjectID(req.params.id) };
      dbclient.db(config.db_name).collection('job').findOne(where, (err, result) => {
        if (err) {
          utools.handleServerException(err, config.user, dbclient, res);
        } 
        else {        
          res.status(200).send(result.schedules);
        } 
      });
    }
    catch(e) {
      utools.handleServerException(e, config.user, dbclient, res);
    }
  });
  app.get('/jobs/:id/schedules/:scheduleId', (req, res) => {    
    //get schedule by scheduleId and by id of job
    try {      
      const where = { '_id': new mongo.ObjectID(req.params.id) };      
      dbclient.db(config.db_name).collection('job').findOne(where, (err, item) => {
        if (err) {
          utools.handleServerException(err, config.user, dbclient, res);
        } 
        else {
          if(item !== null) {
            if(item.schedules !== undefined) {
              const schedule = item.schedules.find((ischedule) => {return ischedule._id.toString() === req.params.stepId});
              if(schedule === undefined)
                utools.handleUserException(messageBox.schedule.noScheduleForJobIdAndScheduleId, 404, res);           
              else
                res.status(200).send(schedule);
            }
            else
              utools.handleUserException(messageBox.schedule.noScheduleForJob, 404, res);  
          }
          else
            utools.handleUserException(messageBox.job.jobNotFound, 404, res);  
        } 
      });
    }
    catch(e) {
      utools.handleServerException(e, config.user, dbclient, res);
    }
  });
  app.post('/jobs/:id/schedules', (req, res) => {
    //create new schedule for a job
    try {
      
    }
    catch(e) {
      
    }
  });
  app.patch('/jobs/:id/schedules/:scheduleId', (req, res) => {
    //updates schedule by jobId and scheduleId
    try {
      
    }
    catch(e) {

    }
  });
  app.delete('/jobs/:id/schedules/:scheduleId', (req, res) => {
    //delete schedule by jobId and scheduleId
    try {

    }
    catch(e) {

    }
  });  
};
//TODO
//user handling
//add check for job and step existing