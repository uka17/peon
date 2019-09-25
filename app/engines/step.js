// engines/step.js
const dbclient = require("../tools/db");
const connection = require('./connection');

/**
 * Execute job's step
 * @param {Object} step Step object to be executed
 * @returns {Boolean} Returns `true` in case of successful execution and `false` in case of failure
 */
async function execute(step) {      
  try {
    let con = (await connection.getConnection(step.connection)).connection;
    if(con) {
      //'postgresql://postgres:255320@172.17.0.2:5432/peon'  
      let result = await dbclient.userQuery(step.command, `${con.type}://${con.login}:${con.password}@${con.host}:${con.port}/${con.database}`);
      return { result: true, affected: result.rowCount };
    }
  }
  catch(e) {
    return { result: false, error: e.message };
  }
}
module.exports.execute = execute;