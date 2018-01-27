// routes/note_routes.js
var mongo = require('mongodb');

module.exports = function(app, client) {
    app.get('/jobs/:id', (req, res) => {        
        const details = { '_id': new mongo.ObjectID(req.params.id) };
        client.db('peon').collection('job').findOne(details, (err, item) => {
          if (err) {
            res.send({'error':'An error has occurred'});
          } else {
            res.send(item);
          } 
        });
      });
    app.post('/jobs', (req, res) => {
      const job = { 
        name: req.body.name, 
        description: req.body.description,
        enabled: req.body.enabled,
        status: "new",
        createdOn: Date.now(),
        createdBy: "test",
        modifiedOn: Date.now(),   
        modifiedBy: "test"
      };     
      client.db('peon').collection('job').insert(job, (err, result) => {
        if (err) { 
          res.send({ 'error': 'An error has occurred' }); 
        } else {
          res.send(result.ops[0]);
        }
      });
    });
  };