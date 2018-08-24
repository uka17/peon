//models/app_models.js
/*
Objective of this schemas  is to check if input from API side (client side): 
- contains all needed fields
- fields have correct data formats
- input do not contains extra fields
- constrains for data (e.g. 24 hours 60 minutes)
It is not relating to DB schema validation anyhow
*/
//var Ajv = require('ajv');

module.exports.jobSchema = {
  $id: 'http://example.com/job',
  type: "object",
  properties: {
    name: {type: 'string'},
    description: {type: 'string'},
    enabled: {type: 'boolean'},
    steps: { "type": "array"},
    schedules: { "type": "array"},
    notifications: { "type": "array"},
    nextRun: {type: 'string', format: 'date-time'}
  },
  additionalProperties: false
};

module.exports.jobSchemaRequired = ['name', 'enabled']

module.exports.stepSchema = {
  $id: 'http://example.com/step',
  type: "object",
  properties: {
    name: {type: 'string'},
    enabled: {type: 'boolean'},      
    connection: {type: 'string'},
    database: {type: 'string'},
    command: {type: 'string'},    
    onSucceed: {oneOf: [
      { enum: ['gotoNextStep', 'quitWithSuccess', 'quitWithFailure'] },
      { type: 'object', properties: { gotoStep: {type: 'integer', minimum: 1}}, additionalProperties: false}
    ]},
    onFailure: {oneOf: [
      { enum: ['gotoNextStep', 'quitWithSuccess', 'quitWithFailure'] },
      { type: 'object', properties: { gotoStep: {type: 'integer', minimum: 1}}, additionalProperties: false}
    ]},
    retryAttempts: {type: 'object', properties: {
        number: {type: 'integer', minimum: 0, maximum: 10},
        interval: {type: 'integer', minimum: 1}
      },
      additionalProperties: false
    }
  },
  additionalProperties: false
};
module.exports.stepSchemaRequired = ['name', 'enabled', 'connection', 'database', 'command', 'onSucceed', 'onFailure', 'retryAttempts']

module.exports.connectionSchema = {
  $id: 'http://example.com/connection',
  type: "object",
  properties: {
    name: {type: 'string'},
    host: {type: 'string'},
    port: {type: 'integer', minimum: 0, maximum: 65536},
    enabled: {type: 'boolean'},      
    login: {type: 'string'},
    password: {type: 'string'},
    type: { enum: ['mongodb', 'postgresql'] } 
  },
  additionalProperties: false
}
module.exports.connectionSchemaRequired = ['name', 'host', 'enabled', 'login', 'password', 'type'];
module.exports.scheduleSchema = require('../schedule/models.json').scheduleSchema;
module.exports.scheduleSchemaDaily = require('../schedule/models.json').scheduleSchemaDaily;