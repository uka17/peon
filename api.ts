// API part of application

import config from "./config/config";
import app from "./app/init/setup";
import Dispatcher from "./log/dispatcher";
const log = Dispatcher.getInstance(config.enableDebugOutput, config.logLevel);

//Startup
app.listen(config.port, () => {
  log.info(`Service is live on ${config.port}.`);
});
