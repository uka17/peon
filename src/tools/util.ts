import { executeSysQuery } from "./db";
import LogDispatcher from "../classes/logDispatcher";
import config from "../config/config";
const log = LogDispatcher.getInstance(
  Boolean(config.enableDebugOutput),
  config.logLevel
);
import bodyParser from "body-parser";
import express from "express";

import toJSON from "utils-error-to-json";
//#region Error handling
/**
 * Puts log record into DB and returns `id` of this record
 * @param {unknown} e Error object
 * @param {string} createdBy Optional. Who triggered error
 * @returns {Promise<number>} Resolves Promis with `logId` or 0 in case of failure. Shows error in console in case of DEV environment or log save failed
 */
function logServerError(e: unknown, createdBy?: string): Promise<number> {
  /* istanbul ignore next */
  if (process.env.NODE_ENV !== "PROD") {
    log.error((e as Record<string, unknown>).stack);
  }
  return new Promise((resolve) => {
    const query = {
      "text": 'SELECT public."fnLog_Insert"($1, $2, $3) as logId',
      "values": [1, toJSON(e), createdBy],
    };

    executeSysQuery(query, (err, result) => {
      try {
        /* istanbul ignore next */
        if (err) {
          log.error(err);
          resolve(0);
        } else
          resolve(
            (result.rows[0] as unknown as Record<string, unknown>)
              .logid as number
          );
      } catch (e2) {
        /* istanbul ignore next */
        log.error((e2 as Record<string, unknown>).stack);
        /* istanbul ignore next */
        resolve(0);
      }
    });
  });
}
//#endregion
/**
 * Copy properties from `dest` to `src` objects
 * @param {object} dest Destination object for content transfer
 * @param {object} src Source object for content transfer
 * @param {boolean} all Create properties in `dest` if it doest't exist
 */
function copyProperties(dest: object, src: object, all = false): void {
  const keys = Object.keys(src);
  for (let index = 0; index < keys.length; index++) {
    if (keys[index] in dest || all) {
      dest[keys[index]] = src[keys[index]];
    }
  }
}
/**
 * Return `date-time` in a proper format
 * @returns {Date} `date-time`
 */
function getDateTime(): Date {
  return new Date();
}

/**
 * Convert string represented `date-time` to native format
 * @param {string} stringDateTime UTC `date-time` represented as a `sting`. Example: `2018-01-31T20:54:23.071Z`
 * @returns {Date | null} `date-time`
 */
function parseDateTime(stringDateTime: string): Date | null {
  const preDate = Date.parse(stringDateTime);
  if (!isNaN(preDate)) return new Date(preDate);
  else return null;
}

/**
 * Return minimal value from array of `date-time`. Not `date-time` values will be ignored.
 * @param {Array<String>} dateTimeList List of string `date-time` values where to search minimal value
 * @returns {Date} `date-time`
 */
function getMinDateTime(dateTimeList: Array<string>): Date {
  const castedDateTimeList: Array<number> = dateTimeList
    .map(parseDateTime)
    .filter((val) => val != null)
    .map((d) => (d as Date).getTime());
  return new Date(Math.min(...castedDateTimeList));
}

/**
 * Returns new express instance, prepared for work with `json`
 * @returns {express.Application}
 */
function expressInstance(): express.Application {
  const app = express();
  app.use(bodyParser.json());

  //Commented it in order to launch Swagger (swagger can not ne launched if json constent type is set as default)
  //app.use(function (req, res, next) {
  //  res.header("Content-Type",'application/json');
  //  next();
  //});
  return app;
}

/**
 * Checks if `value` is a number. Returns `defaultNumber` otherwise.
 * @param {string} value Number which should be checked
 * @param {number} defaultNumber Number which will be returned in case if `value` is not a number
 * @returns {number} Returns value or default number
 */
function isNumber(value: string, defaultNumber: number): number {
  const res = parseInt(value);
  return isNaN(res) ? defaultNumber : (res as number);
}

type PaginationResult = {
  total: number;
  per_page: number;
  current_page: number;
  last_page: number;
  next_page_url: string | null;
  prev_page_url: string | null;
  from: number;
  to: number;
};

/**
 * Generates pagination info object
 * @param {string} baseUrl URL which will be used for generating `next_page_url` and `next_page_url`
 * @param {number} perPage Number of records per page
 * @param {number} page Current page number
 * @param {number} count Total number of records
 * @param {string} filter Filter part
 * @param {string} sort Sorting part
 * @return {PaginationResult}
 */
function pagination(
  baseUrl: string,
  perPage: number,
  page: number,
  count: number,
  filter: string,
  sort: string
): PaginationResult {
  const result: PaginationResult = {
    total: 0,
    per_page: 0,
    current_page: 0,
    last_page: 0,
    next_page_url: "",
    prev_page_url: "",
    from: 0,
    to: 0,
  };
  const lastPage = Math.ceil(count / perPage);
  const nextPage = page == lastPage ? null : page + 1;
  const prevPage = page == 1 ? null : page - 1;
  const filterExpression = filter === undefined ? "" : `&filter=${filter}`;
  const sortExpression = sort === undefined ? "" : `&sort=${sort}`;
  result.total = count;
  result.per_page = perPage;
  result.current_page = page;
  result.last_page = lastPage;
  result.next_page_url =
    nextPage === null
      ? null
      : `${baseUrl}/?page=${nextPage}&per_page=${perPage}${filterExpression}${sortExpression}`;
  result.prev_page_url =
    prevPage === null
      ? null
      : `${baseUrl}/?page=${prevPage}&per_page=${perPage}${filterExpression}${sortExpression}`;
  result.from = perPage * (page - 1) + 1;
  if (page == lastPage) result.to = count;
  else result.to = perPage * page;
  return result;
}
module.exports.pagination = pagination;

export {
  logServerError,
  copyProperties,
  getDateTime,
  parseDateTime,
  getMinDateTime,
  expressInstance,
  isNumber,
  pagination,
};
