// server.js
const config = require('./config/config');
const main = require('./app/engines/main');
const app = require('./app/init/setup').app;
const log = require('./log/dispatcher');

//Startup
app.listen(config.port, () => {
  log.info(`Service is live on ${config.port}.`);
});

//Main loop
setInterval(main.run, config.runInterval, config.runTolerance);

//Startup actions
require('./app/init/on_startup');
