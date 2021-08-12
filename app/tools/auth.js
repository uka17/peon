const jwt = require('express-jwt');
const config = require('../../config/config')

const getTokenFromHeaders = (req) => {
  const { headers: { authorization } } = req;

  if(authorization && authorization.split(' ')[0] === 'Bearer') {
    return authorization.split(' ')[1];
  }
  return null;
};

const auth = {
  required: jwt({
    secret: config.JWT.secret,
    algorithms: ['HS256'],
    userProperty: 'payload',
    getToken: getTokenFromHeaders,
  }),
  optional: jwt({
    secret: config.JWT.secret,
    algorithms: ['HS256'],
    userProperty: 'payload',
    getToken: getTokenFromHeaders,
    credentialsRequired: false,
  }),
};

module.exports = auth;