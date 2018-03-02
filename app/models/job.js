//models/job.js
var Ajv = require('ajv');

module.exports.jobSchema = {
  $id: "job",
  type: "object",
  properties: {
    name: {type: 'string'},
    description: {type: 'string'},
    enabled: {type: 'boolean'},
    createdOn: {type: 'string', format: 'date-time'},
    createdBy: {type: 'string'},
    modifiedOn: {type: 'string', format: 'date-time'},
    modifiedBy: {type: 'string'},
    steps: { "type": "array"}  
  },
  additionalProperties: false
};
 
module.exports.stepSchema = {
  $id: "step",
  type: "object",
  properties: {
    name: {type: 'string'},
    connection: {type: 'string'},
    database: {type: 'string'},
    command: {type: 'string'},
    enabled: {type: 'boolean'},          
    createdOn: {type: 'string', format: 'date-time'},
    createdBy: {type: 'string'},
    modifiedOn: {type: 'string', format: 'date-time'},
    modifiedBy: {type: 'string'}, 
    onSucceed: {oneOf: [
      { enum: ['gotoNextStep', 'quitWithSuccess', 'quitWithFailure'] },
      { type: 'object', properties: { gotoStep: {type: 'integer', minimum: 1}}}
    ]},
    onFailure: {oneOf: [
      { enum: ['gotoNextStep', 'quitWithSuccess', 'quitWithFailure'] },
      { type: 'object', properties: { gotoStep: {type: 'integer', minimum: 1}}}
    ]},
    retryAttempts: {type: 'object', properties: {
        number: {type: 'integer', minimum: 0, maximum: 10},
        interval: {type: 'integer', minimum: 5}
      }
    }
  },
  additionalProperties: false
};

module.exports.scheduleSchema = {
  $id: "schedule",
  type: "object",
  properties: {
    name: {type: 'string'},
    enabled: {type: 'boolean'},
    type: { enum: ['oneTime', 'recurrent'] },
    oneTime: {type: 'string', format: 'date-time'},
    recurrent: {
      type: 'object', 
      properties: { 
        occurs: {enum: ['daily', 'weekly', 'monthly']},
        recursEvery: {type: 'integer', minimum: 1}, //dependent on occurs. E.g. every 2nd week
        dayOfWeek: {
          type: 'array',
          uniqueItems: true,
          items: { enum: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'] },
          additionalItems: false
        }
      },
      required: ['occurs', 'recursEvery', 'dayOfWeek'],
      additionalProperties: false
    },
    createdOn: {type: 'string', format: 'date'},
    createdBy: {type: 'string'},
    modifiedOn: {type: 'string', format: 'date'},
    modifiedBy: {type: 'string'}
  },
  additionalProperties: false
};