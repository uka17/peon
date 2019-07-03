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
            jobStarted: 'Execution started',
            executingStep: (stepName) => `Executing step '${stepName}'`,
            stepExecuted: (stepName) => `Step '${stepName}' successfully executed`,
            stepFailed: (stepName) => `Failed to execute step '${stepName}'`,
            jobFinished: 'Execution finished'
        }
    }
}
