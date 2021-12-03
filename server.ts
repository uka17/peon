// Heart of job execution engine
import config from "./config/config";
import Engine from "./app/classes/engine";

//Main loop
const context: Engine = new Engine(config.runTolerance);
setInterval(function () {
  return context.run();
}, config.runInterval);

//Startup actions
context.updateOverdueJobs();
context.resetAllJobsStatuses();
