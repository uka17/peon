import { executeUserQuery } from "../tools/db";
import Connection from "./connection";
import pg from "pg";

export enum SimpleStepActionType {
  gotoNextStep = "gotoNextStep",
  quitWithSuccess = "quitWithSuccess",
  quitWithFailure = "quitWithFailure",
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

export interface IStep {
  name: string;
  enabled: boolean;
  order: number;
  connection: number;
  command: string;
  onSucceed: SimpleStepActionType | IGotoStepAction;
  onFailure: SimpleStepActionType | IGotoStepAction;
  retryAttempts: IRetryAttempts;
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

  constructor(value: IStep) {
    this.name = value.name;
    this.enabled = value.enabled;
    this.order = value.order;
    this.connection = value.connection;
    this.command = value.command;
    this.onSucceed = value.onSucceed;
    this.onFailure = value.onFailure;
    this.retryAttempts = value.retryAttempts;
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
