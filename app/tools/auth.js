const jwt = require('express-jwt');
const config = require('../../config/config');

const auth = {
  required: jwt({
    secret: config.secret,
    algorithms: ['HS256'],
    userProperty: 'payload',

  }),
  optional: jwt({
    secret: config.secret,
    algorithms: ['HS256'],
    userProperty: 'payload',
    credentialsRequired: false,
  }),
};

module.exports = auth;