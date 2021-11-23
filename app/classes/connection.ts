/* eslint-disable no-unused-vars */
/* eslint-disable no-case-declarations */
/* eslint-disable no-prototype-builtins */

import { executeSysQuery } from "../tools/db";
import ConnectionBody from "./connectionBody";
import pg from "pg";
import Dispatcher from "../../log/dispatcher";
import config from "../../config/config";
const log = Dispatcher.getInstance(config.enableDebugOutput, config.logLevel);
//TODO fix all function descriptions to proper one
export default class Connection {
  public body?: ConnectionBody;
  public id?: number;
  public modifiedOn?: string;
  public modifiedBy?: string;
  public createdOn?: string;
  public createdBy?: string;
  public isDeleted?: boolean;

  /**
   * Creates new `Connection` object
   * @param {ConnectionBody} body Body of new connetion with main attributes
   */
  constructor(body?: ConnectionBody) {
    this.body = body;
  }

  /**
   * Returns `Connection` count accordingly to filtering
   * @param {string} filter Filter will be applied to `name` and `description` columns
   * @returns {Promise<null | number | Error>} Promise which resolves with number of `Connection` objects in case of success, `null` if Connection list is empty and rejects with error in case of failure
   */
  public static count(filter: string): Promise<null | number | Error> {
    return new Promise((resolve, reject) => {
      const query: pg.QueryConfig = {
        "text": 'SELECT public."fnConnection_Count"($1) as count',
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
        } catch (e) {
          /* istanbul ignore next */
          log.error(
            `Failed to get connection count with query ${query}. Stack: ${e}`
          );
          /* istanbul ignore next */
          reject(e);
        }
      });
    });
  }
  //TODO return type to Connection
  /**
   * Returns `Connection` list accordingly to filtering, sorting, page order and page number
   * @param {string} filter Filter will be applied to `name` and `description` columns
   * @param {string} sortColumn Name of sorting column
   * @param {string} sortOrder Sorting order (`asc` or `desc`)
   * @param {number} perPage Number of records per page
   * @param {number} page Page number
   * @returns {Promise<null | number | Error>} Promise which resolves with list of `Connection` objects in case of success, `null` if `Connection` list is empty and rejects with error in case of failure
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
        const query: pg.QueryConfig = {
          "text":
            'SELECT public."fnConnection_SelectAll"($1, $2, $3, $4, $5) as connections',
          "values": [filter, sortColumn, sortOrder, perPage, page],
        };
        executeSysQuery(query, (err, result) => {
          try {
            /* istanbul ignore if */
            if (err) {
              throw err;
            } else {
              /* istanbul ignore if */
              const connections: unknown = (
                result.rows[0] as unknown as Record<string, unknown>
              ).connections;
              if (connections == null) {
                resolve(null);
              } else {
                resolve(connections);
              }
            }
          } catch (e) /*istanbul ignore next*/ {
            log.error(
              `Failed to get conneciton list with query ${query}. Stack: ${e}`
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
   * Returns `Connection` by id
   * @param {number} id Id of `Connection`
   * @returns {Promise<null | Connection | Error>} Promise which returns `Connection` object in case of success, `null` in case if object not found by `id` and rejects with error in case of failure
   */
  public static get(id: number): Promise<null | Connection | Error> {
    return new Promise((resolve, reject) => {
      try {
        const query: pg.QueryConfig = {
          "text": 'SELECT public."fnConnection_Select"($1) as connection',
          "values": [id],
        };
        executeSysQuery(query, (err, result) => {
          try {
            /* istanbul ignore if */
            if (err) {
              throw err;
            } else {
              /* istanbul ignore if */
              const connection: unknown = (
                result.rows[0] as unknown as Record<string, unknown>
              ).connection;
              if (connection == null) {
                resolve(null);
              } else resolve(connection as Connection);
            }
          } catch (e) /*istanbul ignore next*/ {
            log.error(
              `Failed to get connection with query ${query}. Stack: ${e}`
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
   * Creates new Connection in database
   * @param {string} createdBy User who saved connection to database
   * @returns {Promise<null | Connection | Error>} Promise which resolves with just created `Connection` object populated with `id` in case of success and rejects with error in case of failure
   */
  public save(createdBy: string): Promise<null | Connection | Error> {
    return new Promise((resolve, reject) => {
      try {
        const query: pg.QueryConfig = {
          "text": 'SELECT public."fnConnection_Insert"($1, $2) as id',
          "values": [this.body, createdBy],
        };
        executeSysQuery(query, async (err, result) => {
          try {
            /* istanbul ignore if */
            if (err) {
              throw err;
            } else {
              const newBornConnection: Connection = (await Connection.get(
                (result.rows[0] as unknown as Record<string, unknown>)
                  .id as number
              )) as Connection;
              resolve(newBornConnection);
            }
          } catch (e) /*istanbul ignore next*/ {
            log.error(
              `Failed to insert conneciton with query ${query}. Stack: ${e}`
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
   * Updates `Connection` in database
   * @param {string} updatedBy User who updates connection
   * @returns {Promise<number | Error>} Promise which resolves with number of updated rows in case of success and rejects with error in case of failure
   */
  public update(updatedBy: string): Promise<number | Error> {
    return new Promise((resolve, reject) => {
      try {
        if (!this.id)
          throw new Error(
            "Connection was not changed at database level, save it before any changes"
          );
        //TODO add check for body
        const query: pg.QueryConfig = {
          "text": 'SELECT public."fnConnection_Update"($1, $2, $3) as count',
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
            log.error(
              `Failed to update conneciton with query ${query}. Stack: ${e}`
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
   * Marks `Connection` as deleted
   * @param {string} deletedBy Who did this?
   * @returns {Promise<number | Error>} Promise which resolves with number of deleted rows in case of success and rejects with error in case of failure
   */
  public delete(deletedBy: string): Promise<number | Error> {
    return new Promise((resolve, reject) => {
      try {
        if (!this.id)
          throw new Error(
            "Connection was not changed at database level, save it before any changes"
          );
        const query: pg.QueryConfig = {
          "text": 'SELECT public."fnConnection_Delete"($1, $2) as count',
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
            log.error(
              `Failed to delete conneciton with query ${query}. Stack: ${e}`
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
}
