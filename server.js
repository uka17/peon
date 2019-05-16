// server.js
const config = require('./config/config');
const index = require('./app/routes/index');    
const app = require('./app/tools/utools').expressInstance();
const dbclient = require('./app/tools/db');

index(app, dbclient);
app.listen(config.port, () => {
  console.log('We are live on ' + config.port);
});   

