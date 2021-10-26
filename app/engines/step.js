// engines/step.js
const dbclient = require("../tools/db");
const connection = require("./connection");

/**
 * Executes step
 * @param {object} step Step object to be executed
 * @returns {object} Promise which returns `true` and `number` of rows affected in case of successful execution and `false` and error message in case of failure
 */
async function execute(step) {
  try {
    if (typeof step !== "object")
      throw new TypeError("step should be an object");
    let connectionObject = await connection.getConnection(step.connection);
    if (!connectionObject)
      throw new TypeError(
        `connection (id=${step.connection}) can not be found`
      );
    let con = connectionObject.connection;
    if (con) {
      let result = await dbclient.userQuery(
        step.command,
        `${con.type}://${con.login}:${con.password}@${con.host}:${con.port}/${con.database}`
      );
      return { result: true, affected: result.rowCount };
    } else
      throw new TypeError(
        `connection (id=${step.connection}) can be found, but record format is invalid`
      );
  } catch (e) {
    return { result: false, error: e.message };
  }
}
module.exports.execute = execute;

/**
 * Executes step after delay
 * @param {Object} step Step object to be executed
 * @param {number} delay Dealy in seconds befor step will be executed
 * @returns {Promise} Promise which returns `true` and `number` of rows affected in case of successful execution and `false` and error message in case of failure
 */
function delayedExecute(step, delay) {
  return new Promise((resolve, reject) => {
    try {
      if (typeof parseInt(delay) !== "number" || isNaN(parseInt(delay)))
        throw new TypeError("delay should be a number");
      if (typeof step !== "object")
        throw new TypeError("step should be an object");
      setTimeout(() => {
        resolve(module.exports.execute(step));
      }, delay * 1000);
    } catch (err) {
      reject(err);
    }
  });
}

module.exports.delayedExecute = delayedExecute;
