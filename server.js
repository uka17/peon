// server.js
const express = require('express');
const MongoClient = require('mongodb').MongoClient;
const bodyParser = require('body-parser');
const config = require('./config/config');
const app = express();
const port = 8080;

app.use(bodyParser.json());
app.use(function (req, res, next) {
  res.header("Content-Type",'application/json');
  next();
});
MongoClient.connect(config.mongodb_url, (err, dbclient) => {
  if (err) return console.log(err)    
  const index = require('./app/routes/index');    
  index(app, dbclient);
  app.listen(port, () => {
    console.log('We are live on ' + port);
  });               
})