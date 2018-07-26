// server.js
const config = require('./config/config');
const utools = require('./app/tools/utools');
const index = require('./app/routes/index');    

utools.mongoInstancePromise(config.mongodb_url).then(dbclient => {
  let app = utools.expressAppInstance();
  index(app, dbclient);
  app.listen(config.port, () => {
    console.log('We are live on ' + config.port);
  });               
})