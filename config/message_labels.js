/* istanbul ignore next */
module.exports = (language = "en") => {
  return {
    job: {
      jobNotFound: "Job not found",
      jobNextRunUpdated: "Next run date and time were updated",
    },
    step: {
      noStepForJob: "No step found for mentioned jobId",
      noStepForJobAndStep: "No step found for mentioned stepId and jobId",
    },
    schedule: {
      noScheduleForJob: "No schedule found for this job",
      scheduleNoName: "Schedule should have <name> field",
      noScheduleForJobIdAndScheduleId:
        "No schedule found for mentioned jobId and scheduleId",
      nextRunCanNotBeCalculated: "Job next run can not be calculated",
    },
    user: {
      emailRequired: "Email is required",
      passwordRequired: "Password is required",
      incorrectPasswordOrEmail: "Password or email is incorrect",
      emailFormatIncorrect: "Incorrect email format",
      incorrectToken: "Token is incorrect",
      notFound: "User not found",
      alreadyExists: "Email is invalid or already taken",
      passwordFormatIncorrect:
        "Password should have minimum eight characters, at least one letter and one number",
    },
    common: {
      debugMessage:
        "The Lord of Darkness cursed something on our server. We have already called out the Holy Reinforcements and they are trying to fix everything. You can help us to win by sending logId. Amen!",
      updated: "updated",
      deleted: "deleted",
      count: "count",
    },
    execution: {
      jobNoSteps: `No any steps were found for job`,
      jobStarted: `Job execution started`,
      executingStep: (stepName) => `Executing step '${stepName}'`,
      repeatingStep: (stepName, attempt, total) =>
        `Trying to repeat step '${stepName}'. Attempt ${attempt} of ${total}`,
      stepExecuted: (stepName) => `Step '${stepName}' successfully executed`,
      stepRepeatSuccess: (stepName, attempt) =>
        `Step '${stepName}' successfully executed after ${attempt} attempt`,
      stepRepeatFailure: (stepName, attempt) =>
        `${attempt} repeat attempt failed for step '${stepName}'`,
      stepFailed: (stepName) => `Failed to execute step '${stepName}'`,
      jobSuccessful: `Job executed successfully`,
      jobFailed: `Job failed'`,
    },
  };
};
