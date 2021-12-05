// engines/user.js
import * as crypto from "crypto";
import * as jwt from "jsonwebtoken";
import config from "../../config/config";
import { executeSysQuery } from "../tools/db";
import Dispatcher from "../../log/dispatcher";
const log = Dispatcher.getInstance(config.enableDebugOutput, config.logLevel);
import pg from "pg";
import * as util from "../tools/util";
export default class User {
  public email = "";
  public hash = "";
  public salt = "";
  public id = 0;

  /**
   * Creates new user with provided email
   * @param email User email
   */
  constructor(email?: string) {
    if (email) this.email = email;
  }
  /**
   * Set password for user
   * @param password Password value
   */
  public setPassword = (password: string) => {
    this.salt = crypto.randomBytes(16).toString("hex");
    this.hash = crypto
      .pbkdf2Sync(password, this.salt, 10000, 512, "sha512")
      .toString("hex");
  };
  /**
   * Checks if provided password and user one are the same
   * @param password Password value to be checked if it is the same as user one
   * @returns Result of password check
   */
  public validatePassword = (password: string): boolean => {
    const hash = crypto
      .pbkdf2Sync(password, this.salt, 10000, 512, "sha512")
      .toString("hex");
    return this.hash === hash;
  };
  /**
   * Generates JWT for this user
   * @returns The JSON Web Token string
   */
  public generateJWT = (): string => {
    const expirationDate = new Date();
    expirationDate.setDate(expirationDate.getDate() + config.JWT.maxAge);
    return jwt.sign(
      {
        email: this.email,
        id: this.id,
        exp: Math.round(expirationDate.getTime() / 1000),
      },
      config.JWT.secret
    );
  };
  /**
   * Generates user object
   * @returns JSON with user information
   */
  public toAuthJSON = (): Record<string, unknown> => {
    return {
      id: this.id,
      email: this.email,
      token: this.generateJWT(),
    };
  };

  /**
   * Save user to DB
   * @param createdBy Initiator of record DB write
   * @returns Promise with operation result
   */
  public save(createdBy: string): Promise<User | Error> {
    return new Promise((resolve, reject) => {
      try {
        const query: pg.QueryConfig = {
          "text": 'SELECT public."fnUser_Insert"($1, $2, $3, $4) as id',
          "values": [this.email, this.hash, this.salt, createdBy],
        };
        executeSysQuery(query, async (err, result) => {
          try {
            /*istanbul ignore if*/
            if (err) {
              throw err;
            } else {
              const userId: number = (
                result.rows[0] as unknown as Record<string, number>
              ).id;
              const newUser = await User.getById(userId);
              if (newUser) resolve(newUser as User);
              else throw new Error(`User with id=${userId} was not found`);
            }
          } catch (e) /*istanbul ignore next*/ {
            log.error(
              `Failed to create user with content ${this}. Stack: ${e}`
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
   * Searches user in database by id
   * @param id User id
   * @returns Promise with operation result
   */
  public static getById(id: number): Promise<User | null | Error> {
    return new Promise((resolve, reject) => {
      try {
        const query: pg.QueryConfig = {
          "text": 'SELECT public."fnUser_SelectById"($1) as user',
          "values": [id],
        };
        executeSysQuery(query, (err, result) => {
          try {
            /*istanbul ignore if*/
            if (err) {
              throw err;
            } else {
              /* istanbul ignore if */
              if (
                (result.rows[0] as unknown as Record<string, unknown>).user ==
                null
              ) {
                resolve(null);
              } else {
                const dbUser: User = new User();
                util.copyProperties(
                  dbUser,
                  (result.rows[0] as unknown as Record<string, unknown>)
                    .user as Record<string, unknown>
                );
                resolve(dbUser);
              }
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

  /**
   * Searches user in database by email
   * @param email User email
   * @returns Promise with operation result
   */
  public static getByEmail(email: string): Promise<User | null | Error> {
    return new Promise((resolve, reject) => {
      try {
        const query: pg.QueryConfig = {
          "text": 'SELECT public."fnUser_SelectByEmail"($1) as user',
          "values": [email],
        };
        executeSysQuery(query, (err, result) => {
          try {
            /*istanbul ignore if*/
            if (err) {
              throw err;
            } else {
              /* istanbul ignore if */
              if (
                (result.rows[0] as unknown as Record<string, unknown>).user ==
                null
              ) {
                resolve(null);
              } else {
                const dbUser: User = new User();
                util.copyProperties(
                  dbUser,
                  (result.rows[0] as unknown as Record<string, unknown>)
                    .user as Record<string, unknown>
                );
                resolve(dbUser);
              }
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
}
