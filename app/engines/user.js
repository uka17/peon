// engines/user.js
const dbclient = require("../tools/db");
const log = require("../../log/dispatcher");

/**
 *
 * @param {string} email Users email
 * @param {string} hash Password hash
 * @param {string} salt Salt for password
 * @param {string} createdBy Who created this user
 * @returns
 */
function createUser(email, hash, salt, createdBy) {
  return new Promise((resolve, reject) => {
    try {
      //TODO regexp for all string types
      if (typeof email !== "string")
        throw new TypeError("email should be a string");
      if (typeof hash !== "string")
        throw new TypeError("hash should be a string");
      if (typeof salt !== "string")
        throw new TypeError("salt should be a string");
      if (typeof createdBy !== "string")
        throw new TypeError("createdBy should be a string");
      const query = {
        "text": 'SELECT public."fnUser_Insert"($1, $2, $3, $4) as id',
        "values": [email, hash, salt, createdBy],
      };
      dbclient.query(query, async (err, result) => {
        try {
          /*istanbul ignore if*/
          if (err) {
            throw new Error(err);
          } else {
            const newUser = await module.exports.getUserById(result.rows[0].id);
            resolve(newUser);
          }
        } catch (e) /*istanbul ignore next*/ {
          let user = {
            email,
            hash,
            salt,
          };
          log.error(`Failed to create user with content ${user}. Stack: ${e}`);
          reject(e);
        }
      });
    } catch (err) {
      log.error(`Parameters type mismatch. Stack: ${err}`);
      reject(err);
    }
  });
}
module.exports.createUser = createUser;

function getUserById(userId) {
  return new Promise((resolve, reject) => {
    try {
      if (typeof parseInt(userId) !== "number" || isNaN(parseInt(userId)))
        throw new TypeError("userId should be a number");
      const query = {
        "text": 'SELECT public."fnUser_SelectById"($1) as user',
        "values": [parseInt(userId)],
      };
      dbclient.query(query, (err, result) => {
        try {
          /*istanbul ignore if*/
          if (err) {
            throw new Error(err);
          } else {
            /* istanbul ignore if */
            if (result.rows[0].user == null) {
              resolve(null);
            } else resolve(result.rows[0].user);
          }
        } catch (e) /*istanbul ignore next*/ {
          log.error(`Failed to get user with query ${query}. Stack: ${e}`);
          reject(e);
        }
      });
    } catch (err) {
      log.error(`Parameters type mismatch. Stack: ${err}`);
      reject(err);
    }
  });
}
module.exports.getUserById = getUserById;

function getUserByEmail(email) {
  return new Promise((resolve, reject) => {
    try {
      if (typeof email !== "string")
        throw new TypeError("email should be a string");
      const query = {
        "text": 'SELECT public."fnUser_SelectByEmail"($1) as user',
        "values": [email],
      };
      dbclient.query(query, (err, result) => {
        try {
          /*istanbul ignore if*/
          if (err) {
            throw new Error(err);
          } else {
            /* istanbul ignore if */
            if (result.rows[0].user == null) {
              resolve(null);
            } else resolve(result.rows[0].user);
          }
        } catch (e) /*istanbul ignore next*/ {
          log.error(`Failed to get user with query ${query}. Stack: ${e}`);
          reject(e);
        }
      });
    } catch (err) {
      log.error(`Parameters type mismatch. Stack: ${err}`);
      reject(err);
    }
  });
}
module.exports.getUserByEmail = getUserByEmail;
