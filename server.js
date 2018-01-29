// server.js
const express = require('express');
const MongoClient = require('mongodb').MongoClient;
const bodyParser = require('body-parser');
const db = require('./config/db');
const app = express();
const port = 8080;

app.use(bodyParser.json());
MongoClient.connect(db.url, (err, client) => {
    if (err) return console.log(err)
    client.db('peon').collection('job').insert({name: "start"});
    const rout = require('./app/routes/index');    
    rout(app, client);
    app.listen(port, () => {
      console.log('We are live on ' + port);
    });               
  })