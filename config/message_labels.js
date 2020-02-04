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
      jobNoSteps: (jobId) => `No any steps were found for job (id=${jobId})`,
      jobStarted: (jobId) => `Job (id=${jobId}) execution started`,
      executingStep: (stepName) => `Executing step '${stepName}'`,
      repeatingStep: (stepName, attempt, total) => `Trying to repeat step '${stepName}'. Attempt ${attempt} of ${total}`,
      stepExecuted: (stepName) => `Step '${stepName}' successfully executed`,
      stepRepeatSuccess: (stepName, attempt) => `Step '${stepName}' successfully executed after ${attempt} attempt`,
      stepRepeatFailure: (stepName, attempt) => `${attempt} repeat attempt failed for step '${stepName}'`,
      stepFailed: (stepName) => `Failed to execute step '${stepName}'`,
      jobSuccessful: (jobId) => `Job (id=${jobId}) executed successfully`,
      jobFailed: (jobId) => `Job (id=${jobId}) failed'`
    }
  };
};
