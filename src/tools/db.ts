// tools/db.js
import config from "../config/config";
import pg from "pg";
import LogDispatcher from "../classes/logDispatcher";
const log = LogDispatcher.getInstance(
  config.enableDebugOutput,
  config.logLevel
);

//configure data type mapping postgres-node due to convert postgres data type to correct one at node side
pg.types.setTypeParser(20, function (val) {
  return parseInt(val);
});

const sysPool = new pg.Pool({
  "connectionString": config.postgresConnectionString,
  "idleTimeoutMillis": 1000,
  "ssl": config.useDBSSL,
});

/**
 * Returns query object. Systems specific queries. Will be executed under system context.
 * @param {pg.QueryConfig} query Query config object for execution
 * @param {(err: Error, result: pg.QueryArrayResult) => void} callback Callback to be called after query is finished
 * @returns {void | Promise<pg.QueryResult>} Query >object or `Promise` in case if callback is not defined
 */
function executeSysQuery(
  query: pg.QueryConfig,
  callback?: (err: Error, result: pg.QueryArrayResult) => void
): void | Promise<pg.QueryResult> {
  if (callback === undefined) return sysPool.query(query);
  else return sysPool.query(query, callback);
}

/**
 * Returns query object. User specific queries which will be executed under user defined connection string.
 * @param {string} query Query config object for execution
 * @param {string} connectionString User defined connection string to connect to database
 * @param {(err: Error, result: pg.QueryArrayResult) => void} callback Callback to be called after query is finished
 * @returns {void | Promise<pg.QueryResult>} Query object or `Promise` in case if callback is not defined
 */
function executeUserQuery(
  query: string,
  connectionString: string,
  callback?: (err: Error, result: pg.QueryArrayResult) => void
): void | Promise<pg.QueryResult> {
  if (connectionString === undefined) {
    const errorText = `Connection string was not provided for query '${query}'`;
    log.error(errorText);
    throw new Error(errorText);
  }

  /* istanbul ignore next */
  const userPool = new pg.Pool({
    "connectionString": connectionString,
    "idleTimeoutMillis": 1000,
    "ssl": config.useDBSSL,
  });

  //tested in executeSysQuery
  /* istanbul ignore next */
  if (callback === undefined) return userPool.query(query);
  else return userPool.query(query, callback);
}

export { executeSysQuery, executeUserQuery };
