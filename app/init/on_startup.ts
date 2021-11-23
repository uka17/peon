import Engine from "../classes/engine";

const context: Engine = new Engine(1000);
context.updateOverdueJobs();
context.resetAllJobsStatuses();
