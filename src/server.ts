// Heart of job execution engine
import config from "./config/config";
import Engine from "./classes/engine";
import LogDispatcher from "./classes/logDispatcher";
const log = LogDispatcher.getInstance(
  config.enableDebugOutput,
  config.logLevel
);

//Main loop
const context: Engine = new Engine(config.runTolerance);
setInterval(function () {
  return context.run();
}, config.runInterval);

log.console(
  `Service started with job search scope in ${config.runTolerance} minute tolerance`
);

//Startup actions
log.console("Resetting job statuses and updating overdue jobs...");
Engine.updateOverdueJobs();
Engine.resetAllJobsStatuses();
log.console("Up and running 🚀");
