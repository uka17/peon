/* istanbul ignore next */
module.exports = (language = 'en') => {
  return {
    job: { 
      jobNotFound: 'job not found'
    },
    step: { 
      noStepForJob:  'no step found for mentioned jobId',
      noStepForJobAndStep: 'no step found for mentioned stepId and jobId'
    },
    schedule: { 
      noScheduleForJob: 'no schedule found for this job',
      scheduleNoName: 'schedule should have <name> field',
      noScheduleForJobIdAndScheduleId: 'no schedule found for mentioned jobId and scheduleId',
      nextRunCanNotBeCalculated: 'job next run can not be calculated'
    },
    common: {
      debugMessage: 'The Lord of Darkness cursed something on our server. We have already called out the Holy Reinforcements and they are trying to fix everything. You can help us to win by sending logId. Amen!',
      updated: 'updated',
      deleted: 'deleted',
      count: 'count'
    },
    execution: {
      jobNoSteps: `No any steps were found for job`,
      jobStarted: `Job execution started`,
      executingStep: (stepName) => `Executing step '${stepName}'`,
      repeatingStep: (stepName, attempt, total) => `Trying to repeat step '${stepName}'. Attempt ${attempt} of ${total}`,
      stepExecuted: (stepName) => `Step '${stepName}' successfully executed`,
      stepRepeatSuccess: (stepName, attempt) => `Step '${stepName}' successfully executed after ${attempt} attempt`,
      stepRepeatFailure: (stepName, attempt) => `${attempt} repeat attempt failed for step '${stepName}'`,
      stepFailed: (stepName) => `Failed to execute step '${stepName}'`,
      jobSuccessful: `Job executed successfully`,
      jobFailed: `Job failed'`
    }
  };
};
