// routes/step_routes.js
var mongo = require('mongodb');
const user = "test";

module.exports = function(app, client) {
  app.get('/jobs/:id/steps/count', (req, res) => {
    //get jobs steps count
    const where = { '_id': new mongo.ObjectID(req.params.id) };
    client.db('peon').collection('job').aggregate([{$match: where}, {$project: {count: { $size: "$steps"}}}]).toArray((err, result) => {
      if (err) {
        res.status(501).send({error: "Not able to process"});
      } else {        
        res.status(200).send({count: result[0].count});
      } 
    });
  });
  app.get('/jobs/:id/steps', (req, res) => {
    //get jobs steps list
    const where = { '_id': new mongo.ObjectID(req.params.id) };
    client.db('peon').collection('job').findOne(where, (err, result) => {
      if (err) {
        res.status(501).send({error: "Not able to process"});
      } else {        
        res.status(200).send(result.steps);
      } 
    });
  });  
};
//TODO
//errors handling
//user handling