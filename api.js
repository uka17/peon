// api.js
// API part of application

const config = require("./config/config");
const app = require("./app/init/setup").app;
const log = require("./log/dispatcher");

//Startup
app.listen(config.port, () => {
  log.info(`Service is live on ${config.port}.`);
});
