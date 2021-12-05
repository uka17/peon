import config from "../../config/config";
import { executeSysQuery } from "../tools/db";
import Dispatcher from "../../log/dispatcher";
const log = Dispatcher.getInstance(config.enableDebugOutput, config.logLevel);
import { v4 as uuidv4 } from "uuid";
import Job, { IJob } from "./job";
import message_labels from "../../config/message_labels";
const labels = message_labels("en");

export default class Engine {
  private _executionLock: boolean;
  private _tolerance: number;

  /**
   * Creates new `Engine` instance
   * @param {number} tolerance Allowance of job next run scope criteria in minutes (BETWEEN now-tolerance AND now+tolerance)
   */
  constructor(tolerance: number) {
    this._tolerance = tolerance;
  }

  /**
   * Returns `Job` list which should be executed
   * @returns {Promise<Array<Job>| Error>} Promise which returns list of Job records to be executed or rejects with error in case of error
   */
  private getListToRun(): Promise<Array<Job> | Error> {
    return new Promise((resolve, reject) => {
      try {
        const query = {
          "text": 'SELECT public."fnJob_ToRun"($1) as jobs',
          "values": [this._tolerance],
        };
        executeSysQuery(query, (err, queryResult) => {
          /* istanbul ignore if */
          if (err) {
            reject(err);
          } else {
            const result: Array<Job> = [];
            if (!queryResult.rows[0]) resolve(result);
            const jobList =
              ((queryResult.rows[0] as unknown as Record<string, unknown>)
                .jobs as Array<Record<string, unknown>>) ?? [];
            jobList.forEach((job) => {
              result.push(new Job(job as unknown as IJob));
            });
            resolve(result);
          }
        });
      } catch (err) {
        log.error(`Parameters type mismatch. Stack: ${err}`);
        reject(err);
      }
    });
  }

  /**
   * Creates new entry for `Job` history
   * @param {string} message Message to log
   * @param {string} createdBy Author of message
   * @param {?string} uid Session id. Default is `null`
   */
  private logRunHistory(
    message: string,
    createdBy: string,
    uid: string | null = null
  ): void {
    const query = {
      "text": 'SELECT public."fnRunHistory_Insert"($1, $2, $3) as logId',
      "values": [message, uid, createdBy],
    };

    log.info(`${message}. session: ${uid}`);

    executeSysQuery(query, (err, result) => {
      if (err) log.error(err);
    });
  }

  /**
   * Main function for `Job` list processing. Searches for a `Jobs` which should be executed and runs them
   */
  public async run(): Promise<void> {
    //TODO change Enging to singleton
    let currentExecutableJobId = 0;
    try {
      if (this._executionLock) return;
      this._executionLock = true;
      const jobList = (await this.getListToRun()) as Array<Job>;
      if (jobList !== null) {
        const uid = uuidv4();
        log.info(
          `${jobList.length} job(s) in tolerance ${this._tolerance} minute(s) scope to process`
        );
        for (let i = 0; i < jobList.length; i++) {
          const job = jobList[i];
          const executionDateTime = new Date(`${job.nextRun}Z`);
          const currentDateTime = new Date(Date.now());
          if (currentDateTime >= executionDateTime) {
            this.logRunHistory(
              `Starting execution of job (id=${job.id})`,
              config.systemUser,
              uid
            );
            currentExecutableJobId = job.id ?? 0;
            //lock job to avoid second thread
            //TODO status should be defined based on text, but not hardcoded id
            if (!(await job.updateStatus(2))) break;
            job.execute(config.systemUser, uid);
          }
        }
        currentExecutableJobId = 0;
      }
      this._executionLock = false;
    } catch (e) {
      log.error((e as Error).stack);
      //unlock job
      if (currentExecutableJobId !== 0) {
        const failedJob = Job.get(currentExecutableJobId);
        if (failedJob) (failedJob as unknown as Job).updateStatus(1);
      }
      this._executionLock = false;
    }
  }

  /**
   * Reset all jobs statuses to `idle`
   * @return {Promise<number | Error>} Numbed of job for which statuses were reset
   */
  public static resetAllJobsStatuses(): Promise<number | Error> {
    return new Promise((resolve, reject) => {
      const query = {
        "text": 'SELECT public."fnJob_ResetAll"() as count',
      };
      executeSysQuery(query, async (err, result) => {
        try {
          /*istanbul ignore if*/
          if (err) {
            throw err;
          } else {
            resolve(
              (result.rows[0] as unknown as Record<string, unknown>)
                .count as number
            );
          }
        } catch (err) {
          log.error(`Reset job list database query failed. Stack: ${err}`);
          reject(err);
        }
      });
    });
  }

  /**
   * Finds all active jobs (not in `Executing` state, enabled and not deleted) and calculates next run date-time for them
   * @returns {Promise<number | null>} Number of updated jobs
   */
  // TODO change return type to number as in case of Error Promise just rethrow an error, but not return Error (is it, dude?)
  public static updateOverdueJobs(): Promise<number | null> {
    return new Promise((resolve, reject) => {
      try {
        //TODO Move it to Job class, creates set of methods for each DB interaction and exclude databaseRecord[] => Array<Job> method
        const query = {
          "text": 'SELECT public."fnJob_SelectAllOverdue"() as jobs',
        };
        executeSysQuery(query, async (err, queryResult) => {
          try {
            /*istanbul ignore if*/
            if (err) {
              throw err;
            } else {
              /* istanbul ignore if */
              const jobList: Array<Job> = [];
              if (!queryResult.rows[0]) resolve(null);
              const databaseRecordList = (
                queryResult.rows[0] as unknown as Record<string, unknown>
              ).jobs as Array<Record<string, unknown>>;
              databaseRecordList.forEach((job) => {
                jobList.push(new Job(job as unknown as IJob));
              });
              let updatedCounter = 0;
              for (let index = 0; index < jobList.length; index++) {
                const job = jobList[index];
                const jobAssesmentResult = job.calculateNextRun();
                /* istanbul ignore if */
                if (!jobAssesmentResult.isValid)
                  log.warn(
                    `job (id=${job.id}): ${jobAssesmentResult.errorList}`
                  );
                else {
                  await job.updateNextRun(
                    jobAssesmentResult.nextRun!.toUTCString()
                  );
                  await job.logHistory(
                    { message: labels.job.jobNextRunUpdated, level: 2 },
                    config.systemUser
                  );
                  updatedCounter++;
                }
              }
              resolve(updatedCounter);
            }
          } catch (e) /*istanbul ignore next*/ {
            log.error(
              `Failed to get job list with query ${query}. Stack: ${e}`
            );
            reject(e);
          }
        });
      } catch (err) {
        log.error(
          `Failed to recalculate next run for outdated jobs. Stack: ${err}`
        );
        reject(err);
      }
    });
  }
}
