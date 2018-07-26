// server.js
const config = require('./config/config');
const utools = require('./app/tools/utools');
const index = require('./app/routes/index');    

utools.expressMongoInstancePromise(index, config.mongodb_url).then(response => {
  response.app.listen(config.port, () => {
    console.log('We are live on ' + config.port);
  });               
})