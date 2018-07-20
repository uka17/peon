//models/app_models.js
/*
Objective of this schemas  is to check if input from API side (client side): 
- contains all needed fields
- fields have correct data formats
- input do not contains extra fields
- constrains for data (e.g. 24 hours 60 minutes)
It is not relating to DB schema validation anyhow
*/
var Ajv = require('ajv');

module.exports.jobSchema = {
  $id: 'http://example.com/job',
  type: "object",
  properties: {
    name: {type: 'string'},
    description: {type: 'string'},
    enabled: {type: 'boolean'},
    steps: { "type": "array"},
    schedules: { "type": "array"},
    notifications: { "type": "array"}
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

module.exports.scheduleSchema = {
  $id: 'http://example.com/schedule',
  oneOf: [
    {"$ref": "#/definitions/oneTime"},
    {"$ref": "#/definitions/daily"},
    {"$ref": "#/definitions/weekly"},
    {"$ref": "#/definitions/monthly"}
  ],
  definitions: {
    oneTime: {
      type: "object",
      properties: {
        name: {type: 'string'},
        enabled: {type: 'boolean'},
        oneTime: {type: 'string', format: 'date-time'}
      },
      additionalProperties: false,
      required: ['name', 'enabled', 'oneTime']  
    },
    daily: {
      type: "object",
      properties: {
        name: {type: 'string'},
        enabled: {type: 'boolean'},
        startDateTime: {type: 'string', format: 'date-time'},
        eachNDay: {type: 'integer', minimum: 1},
        dailyFrequency: {$ref: 'daily#/'}
      },
      additionalProperties: false,
      required: ['name', 'enabled',  'startDateTime', 'eachNDay', 'dailyFrequency']
    },
    weekly: {
      type: "object",
      properties: {
        name: {type: 'string'},
        enabled: {type: 'boolean'},
        startDateTime: {type: 'string', format: 'date-time'},
        endDateTime: {type: 'string', format: 'date-time'},
        eachNWeek: {type: 'integer', minimum: 1},
        dayOfWeek: {
          type: 'array',
          uniqueItems: true,
          items: { enum: ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'] },
          additionalItems: false
        },
        dailyFrequency: {$ref: 'daily#/'}
      },
      additionalProperties: false,
      required: ['name', 'enabled', 'startDateTime', 'eachNWeek', 'dayOfWeek', 'dailyFrequency']
    },
    monthly: {
      type: "object",
      properties: {
        name: {type: 'string'},
        enabled: {type: 'boolean'},
        startDateTime: {type: 'string', format: 'date-time'},
        endDateTime: {type: 'string', format: 'date-time'},
        month: {
          type: 'array',
          uniqueItems: true,
          items: { enum: ['jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec'] },
          additionalItems: false
        },
        //TODO check feb and short months
        day: {type: 'integer', minimum: 1, maximum: 31},
        dailyFrequency: {$ref: 'daily#/'}
      },
      additionalProperties: false,
      required: ['name', 'enabled', 'startDateTime', 'month', 'day', 'dailyFrequency']
    }
  }
}

module.exports.scheduleSchemaDaily = {
  $id: 'http://example.com/daily',
  oneOf: [
    {"$ref": "#/definitions/once"},
    {"$ref": "#/definitions/every"}
  ],
  definitions: {
    once: {
      type: 'object', 
      properties: { occursOnceAt: {type: 'string', format: 'time'}},
      additionalProperties: false,
      required: ['occursOnceAt']
    },
    every: {
      type: 'object', 
      properties: {
        start: {type: 'string', format: 'time'},
        occursEvery: { 
          type: 'object', 
          properties: { 
            //TODO check for 24 and 59
            intervalValue: {type: 'integer', minimum: 0},
            intervalType: { type: 'string', enum: ['minute', 'hour'] }            
          },
		  additionalProperties: false,
          required: ['intervalValue', 'intervalType']
        },
      },
      additionalProperties: false,
      required: ['start', 'occursEvery']
    }
  }
}