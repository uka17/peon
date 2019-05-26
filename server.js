// server.js
const config = require('./config/config');
const index = require('./app/routes/index');    
const app = require('./app/tools/util').expressInstance();
const dbclient = require('./app/tools/db');
const main = require('./app/engine/main');

index(app, dbclient);
app.listen(config.port, () => {
  console.log('We are live on ' + config.port);
});

setInterval(main.run, 1000, 100);
   

