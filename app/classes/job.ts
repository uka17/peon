/* eslint-disable no-unused-vars */
/* eslint-disable no-case-declarations */
/* eslint-disable no-prototype-builtins */
import JobBody from "./jobBody";
import validation from "../tools/validation";
import pg from "pg";
//TODO implement gotoStep: %step_number%
import schedulator from "schedulator";
import * as util from "../tools/util";
import { executeSysQuery } from "../tools/db";
import Step from "./step";
import { SimpleStepActionType } from "./step";
import Dispatcher from "../../log/dispatcher";
import config from "../../config/config";
const log = Dispatcher.getInstance(config.enableDebugOutput, config.logLevel);
import message_labels from "../../config/message_labels";
const labels = message_labels("en");

type NextRunResult = {
  isValid: boolean;
  errorList?: string;
  nextRun?: Date;
};

export interface IJob {
  id?: number;
  body: JobBody;
  //TODO Date?
  modifiedOn?: string;
  modifiedBy?: string;
  createdOn?: string;
  createdBy?: string;
  isDeleted?: boolean;
  statusId?: number;
  nextRun?: string;
  lastRunOn?: string;
  lastRunResult?: boolean;
}

export default class Job implements IJob {
  public id?: number;
  public body: JobBody;
  //TODO Date?
  public modifiedOn?: string;
  public modifiedBy?: string;
  public createdOn?: string;
  public createdBy?: string;
  public isDeleted?: boolean;
  public statusId?: number;
  public nextRun?: string;
  public lastRunOn?: string;
  public lastRunResult?: boolean;

  //TODO change constructor in order to be able to read full object from database
  /**
   * Creates new `Job` object
   * @param {IJob} body Object with all or partial set of attributes
   */
  constructor(job?: IJob) {
    if (job)
      //this.body = job.body;
      util.copyProperties(this, job, true);
  }

  //TODO here and in connection change logic and type from Promise<null | number | Error> to Promise<number | Error>
  /**
   * Returns `Jobs` count accordingly to filtering
   * @param {string} filter Filter will be applied to `name` and `description` columns
   * @returns {Promise<null | number | Error>} Promise which resolves with number of `Job` objects in case of success and rejects with `Error` in case of failure
   */
  public static count(filter = ""): Promise<null | number | Error> {
    return new Promise((resolve, reject) => {
      const query = {
        "text": 'SELECT public."fnJob_Count"($1) as count',
        "values": [filter],
      };
      executeSysQuery(query, (err, result) => {
        try {
          /* istanbul ignore if */
          if (err) {
            throw err;
          } else {
            /* istanbul ignore if */
            if (
              (result.rows[0] as unknown as Record<string, unknown>).count ==
              null
            ) {
              resolve(null);
            } else
              resolve(
                (result.rows[0] as unknown as Record<string, unknown>)
                  .count as number
              );
          }
        } catch (e) /*istanbul ignore next*/ {
          log.error(`Failed to get job count with query ${query}. Stack: ${e}`);
          reject(e);
        }
      });
    });
  }
  //TODO return type to Job
  /**
   * Returns `Job` list accordingly to filtering, sorting, page order and page number
   * @param {string} filter Filter will be applied to `name` and `description` columns
   * @param {string} sortColumn Name of sorting column
   * @param {string} sortOrder Sorting order (`asc` or `desc`)
   * @param {number} perPage Number of records per page
   * @param {number} page Page number
   * @returns {Promise<null | number | Error>} Promise which resolves with list of `Job` objects in case of success, `null` if `Job` list is empty and rejects with error in case of failure
   */
  public static list(
    filter: string,
    sortColumn: string,
    sortOrder: string,
    perPage: number,
    page: number
  ): Promise<null | unknown | Error> {
    return new Promise((resolve, reject) => {
      try {
        if (sortOrder !== "asc" && sortOrder !== "desc")
          throw new TypeError("sortOrder should have value `asc` or `desc`");
        const query = {
          "text": 'SELECT public."fnJob_SelectAll"($1, $2, $3, $4, $5) as jobs',
          "values": [filter, sortColumn, sortOrder, perPage, page],
        };
        executeSysQuery(query, (err, result) => {
          try {
            /* istanbul ignore if */
            if (err) {
              throw err;
            } else {
              /* istanbul ignore if */
              const jobs: unknown = (
                result.rows[0] as unknown as Record<string, unknown>
              ).jobs;
              if (jobs == null) {
                resolve(null);
              } else {
                resolve(jobs);
              }
            }
          } catch (e) /*istanbul ignore next*/ {
            log.error(
              `Failed to get job list with query ${query}. Stack: ${e}`
            );
            reject(e);
          }
        });
      } catch (err) {
        log.error(`Parameters type mismatch. Stack: ${err}`);
        reject(err);
      }
    });
  }

  /**
   * Returns `Job` by id
   * @param {number} jobId Id of `Job`
   * @returns {Promise<null | Job | Error>} Promise which returns `Job` object in case of success, `null` in case if object not found by `id` and rejects with error in case of failure
   */
  public static get(jobId: number): Promise<null | Job | Error> {
    return new Promise((resolve, reject) => {
      try {
        const query = {
          "text": 'SELECT public."fnJob_Select"($1) as job',
          "values": [jobId],
        };
        executeSysQuery(query, (err, result) => {
          try {
            /* istanbul ignore if */
            if (err) {
              throw err;
            } else {
              /* istanbul ignore if */
              const job: unknown = (
                result.rows[0] as unknown as Record<string, unknown>
              ).job;
              if (job == null) {
                resolve(null);
              } else resolve(new Job(job as Job));
            }
          } catch (e) /*istanbul ignore next*/ {
            log.error(`Failed to get job with query ${query}. Stack: ${e}`);
            reject(e);
          }
        });
      } catch (err) {
        log.error(`Parameters type mismatch. Stack: ${err}`);
        reject(err);
      }
    });
  }

  /**
   * Creates new `Job` in database
   * @param {string} createdBy User who saved job to database
   * @returns {Promise<null | Job | Error>} Promise which resolves with just created `Job` object populated with `id` in case of success and rejects with error in case of failure
   */
  public save(createdBy: string): Promise<null | Job | Error> {
    return new Promise((resolve, reject) => {
      try {
        const query = {
          "text": 'SELECT public."fnJob_Insert"($1, $2) as id',
          "values": [this.body, createdBy],
        };
        executeSysQuery(query, async (err, result) => {
          try {
            /* istanbul ignore if */
            if (err) {
              throw err;
            } else {
              const newBornJob: Job = (await Job.get(
                (result.rows[0] as unknown as Record<string, unknown>)
                  .id as number
              )) as Job;
              resolve(newBornJob);
            }
          } catch (e) /*istanbul ignore next*/ {
            log.error(`Failed to insert job with query ${query}. Stack: ${e}`);
            reject(e);
          }
        });
      } catch (err) {
        log.error(`Parameters type mismatch. Stack: ${err}`);
        reject(err);
      }
    });
  }
  /**
   * Updates `Job` in database
   * @param {string} updatedBy User who updates `Job`
   * @returns {Promise<number | Error>} Promise which resolves with number of updated rows in case of success and rejects with error in case of failure
   */
  public update(updatedBy: string): Promise<number | Error> {
    return new Promise((resolve, reject) => {
      try {
        if (!this.id)
          throw new Error(
            "Job was not changed at database level, save it before any changes"
          );
        //TODO add check for body
        const query: pg.QueryConfig = {
          "text": 'SELECT public."fnJob_Update"($1, $2, $3) as count',
          "values": [this.id, this.body, updatedBy],
        };
        executeSysQuery(query, async (err, result) => {
          try {
            /* istanbul ignore if */
            if (err) {
              throw err;
            } else {
              resolve(
                (result.rows[0] as unknown as Record<string, unknown>)
                  .count as number
              );
            }
          } catch (e) /*istanbul ignore next*/ {
            log.error(`Failed to update job with query ${query}. Stack: ${e}`);
            reject(e);
          }
        });
      } catch (err) {
        log.error(`Parameters type mismatch. Stack: ${err}`);
        reject(err);
      }
    });
  }

  /**
   * Marks `Job` as deleted
   * @param {string} deletedBy Who did this?
   * @returns {Promise<null | number | Error>} Promise which resolves with number of deleted rows in case of success and rejects with error in case of failure
   */
  public delete(deletedBy: string): Promise<null | number | Error> {
    return new Promise((resolve, reject) => {
      try {
        if (!this.id)
          throw new Error(
            "Job was not changed at database level, save it before any changes"
          );
        const query: pg.QueryConfig = {
          "text": 'SELECT public."fnJob_Delete"($1, $2) as count',
          "values": [this.id, deletedBy],
        };
        executeSysQuery(query, async (err, result) => {
          try {
            /* istanbul ignore if */
            if (err) {
              throw err;
            } else {
              resolve(
                (result.rows[0] as unknown as Record<string, unknown>)
                  .count as number
              );
            }
          } catch (e) /*istanbul ignore next*/ {
            log.error(`Failed to delete job with query ${query}. Stack: ${e}`);
            reject(e);
          }
        });
      } catch (err) {
        log.error(`Parameters type mismatch. Stack: ${err}`);
        reject(err);
      }
    });
  }

  /**
   * Validates `Job` and calculates next run date and time for it
   * @return {NextRunResult}  Returns assessment result and next attributes: errorList in case of any error, nextRun (in case of success) - next run `date-time`
   */
  public calculateNextRun(): NextRunResult {
    try {
      if (this.body === undefined)
        throw new Error(
          "Unable to calculate next run as Job object is not composed properly"
        );

      const validationSequence: Array<string> = [
        "job",
        "steps",
        "notifications",
        "schedules",
      ];
      let jobValidationResult: NextRunResult = { isValid: false };
      for (let i = 0; i < validationSequence.length; i++) {
        switch (validationSequence[i]) {
          case "job":
            jobValidationResult = validation.validateJob(this.body);
            break;
          case "steps":
            jobValidationResult = validation.validateStepList(this.body.steps);
            break;
          case "notifications":
            //TODO validation for notification
            //jobValidationResult = validation.validateStepList(job.steps)
            break;
          case "schedules":
            const nextRunList: Array<unknown> = [];
            if (this.body.schedules) {
              for (let i = 0; i < this.body.schedules.length; i++) {
                if (this.body.schedules[i].enabled) {
                  if (!this.body.schedules[i].hasOwnProperty("name"))
                    throw new Error(labels.schedule.scheduleNoName);
                  const nextRun = schedulator.nextOccurrence(
                    this.body.schedules[i]
                  );
                  if (nextRun.result != null) nextRunList.push(nextRun.result);
                  else if (nextRun.error!.includes("schema is incorrect"))
                    throw new Error(`schedule[${i}] ${nextRun.error}`);
                }
              }
            }
            if (nextRunList.length == 0)
              throw new Error(labels.schedule.nextRunCanNotBeCalculated);
            else
              jobValidationResult = {
                "isValid": true,
                "nextRun": util.getMinDateTime(nextRunList as string[]),
              };
            break;
        }
        if (!jobValidationResult.isValid) return jobValidationResult;
      }
      return jobValidationResult;
    } catch (e: unknown) {
      log.warn(
        `Failed to calculate next run for job (jobId=${this.id}). Stack: ${e}`
      );
      return {
        "isValid": false,
        "errorList": (e as Record<string, unknown>).message as string,
      };
    }
  }

  /**
   * Calculates and saves in database `Job` next run
   * @param {Date} nextRun `date-time` of job next run
   * @returns {Promise<boolean | Error >} Promise which returns `true` in case of success and `Error` in case of failure
   */
  //TODO change nextRun to Date
  public updateNextRun(nextRun: string | null): Promise<boolean> {
    return new Promise((resolve, reject) => {
      try {
        if (this.body === undefined || this.id === undefined)
          throw new Error(
            "Unable to calculate next run as Job object is not composed properly"
          );
        if (!(util.parseDateTime(nextRun!) instanceof Date) && nextRun === null)
          throw new TypeError("nextRun should be a date-time or null");
        const query = {
          "text": 'SELECT public."fnJob_UpdateNextRun"($1, $2) as count',
          "values": [this.id, nextRun],
        };
        executeSysQuery(query, (err) => {
          try {
            /*istanbul ignore if*/
            if (err) {
              throw err;
            } else {
              resolve(true);
            }
          } catch (e) /*istanbul ignore next*/ {
            log.error(
              `Failed to update job next run with query ${query}. Stack: ${e}`
            );
            reject(e);
          }
        });
      } catch (err) {
        log.error(`Parameters type mismatch. Stack: ${err}`);
        reject(err);
      }
    });
  }

  /**
   * Changes `Job` last run result. Last run date-time will be updated with current timestamp.
   * @param {boolean} runResult Job run result. `true` - success, `false` - failure
   * @returns {Promise<boolean | Error>} Promise which returns `true` in case of success and `Error` in case of failure
   */
  public updateLastRun(runResult: boolean): Promise<boolean | Error> {
    return new Promise((resolve, reject) => {
      try {
        if (this.body === undefined || this.id === undefined)
          throw new Error(
            "Unable to calculate last run as Job object is not composed properly"
          );
        const query = {
          "text": 'SELECT public."fnJob_UpdateLastRun"($1, $2) as updated',
          "values": [this.id, runResult],
        };

        // eslint-disable-next-line no-unused-vars
        executeSysQuery(query, (err) => {
          try {
            /*istanbul ignore if*/
            if (err) {
              throw err;
            } else resolve(true);
          } catch (e) /*istanbul ignore next*/ {
            log.error(
              `Failed to update job last run with query ${query}. Stack: ${e}`
            );
            reject(e);
          }
        });
      } catch (err) {
        log.error(`Parameters type mismatch. Stack: ${err}`);
        reject(err);
      }
    });
  }
  /**
   * Changes `Job` status
   * @param {number} status Status id. `1` - idle, `2` - execution
   * @returns {Promise<boolean | Error>} Promise which returns `true` in case of success and `Error` in case of failure
   */
  public updateStatus(status: number): Promise<boolean | Error> {
    return new Promise((resolve, reject) => {
      try {
        if (this.id === undefined)
          throw new Error(
            "Unable to update status as Job object doesn't have an ID"
          );
        if (status !== 1 && status !== 2)
          throw new TypeError("status should be 1 or 2");
        const query = {
          "text": 'SELECT public."fnJob_UpdateStatus"($1, $2) as updated',
          "values": [this.id, status],
        };

        // eslint-disable-next-line no-unused-vars
        executeSysQuery(query, (err) => {
          try {
            /*istanbul ignore if*/
            if (err) {
              throw err;
            } else resolve(true);
          } catch (e) /*istanbul ignore next*/ {
            log.error(
              `Failed to update job status with query ${query}. Stack: ${e}`
            );
            reject(e);
          }
        });
      } catch (err) {
        log.error(`Parameters type mismatch. Stack: ${err}`);
        reject(err);
      }
    });
  }

  /**
   * Creates new entry for job history
   * @param {Record<string, unknown>} message message to log
   * @param {string} createdBy Author of message
   * @param {?string} uid Session id. Default is `null`
   * @returns {Promise<boolean | Error>} Promise which returns `true` in case of success and `Error` in case of failure
   */
  public logHistory(
    message: Record<string, unknown>,
    createdBy: string,
    uid?: string
  ): Promise<boolean | Error> {
    return new Promise((resolve, reject) => {
      try {
        if (this.id === undefined)
          throw new Error(
            "Unable to log history as Job object doesn't have an ID"
          );
        if (typeof createdBy !== "string")
          throw new TypeError("createdBy should be a string");
        const query = {
          "text":
            'SELECT public."fnJobHistory_Insert"($1, $2, $3, $4) as updated',
          "values": [message, uid ?? null, this.id, createdBy],
        };

        log.info(
          `Job (id=${this.id}). ${message.message}${
            message.error ? ": " + message.error : ""
          }`
        );

        // eslint-disable-next-line no-unused-vars
        executeSysQuery(query, (err) => {
          try {
            /*istanbul ignore if*/
            if (err) {
              throw err;
            } else resolve(true);
          } catch (e) /*istanbul ignore next*/ {
            log.error(
              `Failed to add record to log job history with query ${query}. Stack: ${e}`
            );
            reject(e);
          }
        });
      } catch (err) {
        log.error(`Parameters type mismatch. Stack: ${err}`);
        reject(err);
      }
    });
  }

  //TODO think about segregating execution, changing last run and calculating next run
  /**
   * Executes `Job` (including logging steps results, changing `Job` last run result and `date-time`, calculates next run `date-time`).
   * @param {string} executedBy User who is executing job
   * @param {?string} uid Session id. Default is `null`
   */
  public async execute(executedBy: string, uid: string): Promise<void> {
    try {
      if (this.body === undefined || this.id === undefined)
        throw new Error(
          "Unable to calculate next run as Job object is not composed properly"
        );
      await this.logHistory(
        { message: labels.execution.jobStarted, level: 2 },
        executedBy,
        uid
      );
      let jobExecutionResult = true;
      if (this.body.hasOwnProperty("steps") && this.body.steps.length > 0) {
        //TODO sort steps in right order
        step_loop: for (
          let stepIndex = 0;
          stepIndex < this.body.steps.length;
          stepIndex++
        ) {
          const step = new Step(
            this.body.steps[stepIndex] as unknown as Record<string, unknown>
          );
          await this.logHistory(
            {
              message: labels.execution.executingStep(step.name),
              level: 2,
            },
            executedBy,
            uid
          );
          const stepExecution = await step.execute();
          //log execution result
          if (stepExecution.result) {
            await this.logHistory(
              {
                message: labels.execution.stepExecuted(step.name),
                rowsAffected: stepExecution.affected,
                level: 2,
              },
              executedBy,
              uid
            );
            //take an action based on execution result
            switch (step.onSucceed) {
              case SimpleStepActionType.gotoNextStep:
                break;
              case SimpleStepActionType.quitWithSuccess:
                jobExecutionResult = true;
                break step_loop;
              case SimpleStepActionType.quitWithFailure:
                jobExecutionResult = false;
                break step_loop;
            }
          } else {
            await this.logHistory(
              {
                message: labels.execution.stepFailed(step.name),
                error: stepExecution.error,
                level: 0,
              },
              executedBy,
              uid
            );
            let repeatSucceeded = false;
            //There is a requierement to try to repeat step in case of failure
            if (step.retryAttempts.number > 0) {
              attempt_loop: for (
                let attempt = 0;
                attempt < step.retryAttempts.number;
                attempt++
              ) {
                await this.logHistory(
                  {
                    message: labels.execution.repeatingStep(
                      step.name,
                      attempt + 1,
                      step.retryAttempts.number
                    ),
                    level: 2,
                  },
                  executedBy,
                  uid
                );
                const repeatExecution = await step.delayedExecute(
                  step.retryAttempts.interval
                );
                if (repeatExecution.result) {
                  await this.logHistory(
                    {
                      message: labels.execution.stepRepeatSuccess(
                        step.name,
                        attempt + 1
                      ),
                      rowsAffected: stepExecution.affected,
                      level: 2,
                    },
                    executedBy,
                    uid
                  );
                  //take an action based on execution result
                  switch (step.onSucceed) {
                    case SimpleStepActionType.gotoNextStep:
                      repeatSucceeded = true;
                      break attempt_loop;
                    case SimpleStepActionType.quitWithSuccess:
                      jobExecutionResult = true;
                      break step_loop;
                    case SimpleStepActionType.quitWithFailure:
                      jobExecutionResult = false;
                      break step_loop;
                  }
                } else {
                  await this.logHistory(
                    {
                      message: labels.execution.stepRepeatFailure(
                        step.name,
                        attempt + 1
                      ),
                      error: stepExecution.error,
                      level: 0,
                    },
                    executedBy,
                    uid
                  );
                }
              }
            }
            if (!repeatSucceeded) {
              //all aditional attempts failed
              switch (step.onFailure) {
                case SimpleStepActionType.gotoNextStep:
                  break;
                case SimpleStepActionType.quitWithSuccess:
                  jobExecutionResult = true;
                  break step_loop;
                case SimpleStepActionType.quitWithFailure:
                  jobExecutionResult = false;
                  break step_loop;
              }
            }
          }
        }
      } else {
        await this.logHistory(
          { message: labels.execution.jobNoSteps, level: 0 },
          executedBy,
          uid
        );
      }
      await this.updateLastRun(jobExecutionResult);
      if (jobExecutionResult) {
        await this.logHistory(
          { message: labels.execution.jobSuccessful, level: 2 },
          executedBy,
          uid
        );
      } else {
        await this.logHistory(
          { message: labels.execution.jobFailed, level: 0 },

          executedBy,
          uid
        );
      }

      const jobAssesmentResult: NextRunResult = this.calculateNextRun();
      if (!jobAssesmentResult.isValid) {
        await this.updateNextRun(null);
      } else {
        await this.updateNextRun(jobAssesmentResult.nextRun!.toUTCString());
      }
    } catch (e) {
      log.error(
        `Error during execution of job (jobRecord=${this}). Stack: ${e}`
      );
    } finally {
      if (this !== null && this !== undefined) this.updateStatus(1);
    }
  }

  /**
   * Sorting `Step` list in a correct order and eliminates gaps in sorting order (e.g. 1,7,2,2,9 will be changed to 1,2,3,4,5)
   */
  public normalizeStepList(): void {
    if (!this.body?.steps)
      throw new Error("Job doesn't contain step list to be normilized");
    //sort steps in correct order
    if (!Array.isArray(this.body?.steps))
      throw new Error("stepList should have type Array");
    this.body.steps.sort((a, b) => {
      if (!a.hasOwnProperty("order") || !b.hasOwnProperty("order"))
        throw new Error(
          `All 'Step' objects in the list should have 'order' property`
        );

      if (a.order < b.order) return -1;
      if (a.order > b.order) return 1;
      return 0;
    });
    //normalize
    for (let index = 0; index < this.body.steps.length; index++) {
      this.body.steps[index].order = index + 1;
    }
  }
}
