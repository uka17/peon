// server.js
// Heart of job execution engine
const config = require("./config/config");
const main = require("./app/engines/main");

//Main loop
setInterval(main.run, config.runInterval, config.runTolerance);

//Startup actions
require("./app/init/on_startup");
