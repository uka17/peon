// engine/step.js
const validation = require("../tools/validation");
const schedulator = require("schedulator");
const util = require('../tools/util')
const dbclient = require("../tools/db");
const messageBox = require('../../config/message_labels');
const log = require('../../log/dispatcher');
const toJSON = require( 'utils-error-to-json' );
const connection = require('./connection');
const jobEngine = require('./job');

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