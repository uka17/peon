import jwt from "express-jwt";
import config from "../../config/config";
import express from "express";

/**
 * Extracts token from header
 * @param {express.Request} req Request object
 * @returns {null | string} Token or null
 */
const getTokenFromHeaders = (req: express.Request): null | string => {
  const {
    headers: { authorization },
  } = req;

  if (authorization && authorization.split(" ")[0] === "Bearer") {
    return authorization.split(" ")[1];
  }
  return null;
};

export default {
  required: jwt({
    secret: config.JWT.secret,
    algorithms: ["HS256"],
    userProperty: "payload",
    getToken: getTokenFromHeaders,
  }),
  optional: jwt({
    secret: config.JWT.secret,
    algorithms: ["HS256"],
    userProperty: "payload",
    getToken: getTokenFromHeaders,
    credentialsRequired: false,
  }),
};
