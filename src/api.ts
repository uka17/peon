// API part of application

import config from "./config/config";
import app from "./init/setup";
import LogDispatcher from "./classes/logDispatcher";
const log = LogDispatcher.getInstance(
  config.enableDebugOutput,
  config.logLevel
);

//Startup
app.listen(config.port, () => {
  log.console(`Service is live on ${config.port}.`);
});
