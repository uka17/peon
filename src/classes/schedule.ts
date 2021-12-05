//TODO didn't even started to do schedule - dummy file copied from step

import { executeUserQuery } from "../tools/db";
import Connection from "./connection";
import pg from "pg";

export enum SimpleStepActionType {
  "gotoNextStep",
  "quitWithSuccess",
  "quitWithFailure",
}

export type StepExecutionResult = {
  result: boolean;
  affected?: number;
  error?: string;
};

export interface IGotoStepAction {
  gotoStep: number;
}

export interface IRetryAttempts {
  number: number;
  interval: number;
}

export default class Step {
  public name = "";
  public enabled = true;
  public order = 0;
  public connection = 0;
  public command = "";
  public onSucceed: SimpleStepActionType | IGotoStepAction;
  public onFailure: SimpleStepActionType | IGotoStepAction;
  public retryAttempts: IRetryAttempts;

  constructor(value: Record<string, unknown>) {
    this.name = value.name as string;
    this.enabled = value.enabled as boolean;
    this.order = value.order as number;
    this.connection = value.connection as number;
    this.command = value.command as string;
    this.onSucceed = value.onSucceed as SimpleStepActionType | IGotoStepAction;
    this.onFailure = value.onFailure as SimpleStepActionType | IGotoStepAction;
    this.retryAttempts = value.retryAttempts as IRetryAttempts;
  }

  /**
   * Executes step
   * @returns {Promise<StepExecutionResult>} Promise which returns `true` and `number` of rows affected in case of successful execution and `false` and error message in case of failure
   */
  public async execute(): Promise<StepExecutionResult> {
    try {
      if (this.connection === 0 || this.command === "")
        throw new Error(
          "Unable to execute as Step object is not composed properly"
        );
      const connectionObject = await Connection.get(this.connection);
      if (!connectionObject)
        throw new TypeError(
          `connection (id=${this.connection}) can not be found`
        );
      const con = (connectionObject as Connection).body;
      if (con) {
        const result = (await executeUserQuery(
          this.command,
          `${con.type}://${con.login}:${con.password}@${con.host}:${con.port}/${con.database}`
        )) as pg.QueryResult;
        return { result: true, affected: result.rowCount };
      } else
        throw new TypeError(
          `connection (id=${this.connection}) can be found, but record format is invalid`
        );
    } catch (e: unknown) {
      return {
        result: false,
        error: (e as Record<string, unknown>).message as string,
      };
    }
  }

  /**
   * Executes step after delay
   * @param {number} delay Delay in seconds before step will be executed
   * @returns {Promise<StepExecutionResult>} Promise which returns `true` and `number` of rows affected in case of successful execution and `false` and error message in case of failure
   */
  public delayedExecute(delay: number): Promise<StepExecutionResult> {
    return new Promise((resolve, reject) => {
      try {
        if (this.connection === 0 || this.command === "")
          throw new Error(
            "Unable to execute as Step object is not composed properly"
          );
        setTimeout(() => {
          resolve(this.execute());
        }, delay * 1000);
      } catch (err) {
        reject(err);
      }
    });
  }
}
