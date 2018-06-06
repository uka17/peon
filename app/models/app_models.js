//models/app_models.js
/*
Purpose of this schema validator is to check if input from API side (client side): 
- contains all needed fields
- fields have correct data format
- input do not contains extra fields
It is not relating to DB schema validation anyhow
*/
var Ajv = require('ajv');

module.exports.jobSchema = {
  type: "object",
  properties: {
    name: {type: 'string'},
    description: {type: 'string'},
    enabled: {type: 'boolean'},
    steps: { "type": "array"}  
  },
  additionalProperties: false
};

module.exports.jobSchemaRequired = ['name']

module.exports.stepSchema = {
  type: "object",
  properties: {
    name: {type: 'string'},
    enabled: {type: 'boolean'},      
    connection: {type: 'object'},
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

module.exports.stepSchemaRequired = ['name', 'connection', 'database', 'command', 'onSucceed', 'onFailure', 'retryAttempts']

module.exports.scheduleSchema = {
  oneOf: [
    {"$ref": "#/definitions/oneTime"},
    {"$ref": "#/definitions/daily"}
  ],
  definitions: {
    oneTime: {
      type: "object",
      properties: {
        name: {type: 'string'},
        enabled: {type: 'boolean'},
        oneTime: {type: 'string', format: 'date-time'}
      },
      additionalProperties: false      
    },
    daily: {
      type: "object",
      properties: {
        name: {type: 'string'},
        enabled: {type: 'boolean'},
        eachNDay: {type: 'integer', minimum: 1},
        dailyFrequency: {$ref: 'daily-frequency#/'}
      },
      additionalProperties: false
    }
  }
}

module.exports.scheduleSchemaDaily = {
  $id: "Daily",
  type: 'object', 
  properties: { 
    eachNDay: {type: 'integer', minimum: 1},
    dailyFrequency: {type: 'object'}
  },
  additionalProperties: false
};

module.exports.scheduleSchemaDailyFrequency = {
  $id: 'http://example.com/daily-frequency',
  oneOf: [
    {"$ref": "#/definitions/once"},
    {"$ref": "#/definitions/every"}
  ],
  definitions: {
    once: {
      type: 'object', 
      properties: { occursOnceAt: {type: 'string', format: 'time'}},
      additionalProperties: false      
    },
    every: {
      type: 'object', 
      properties: { 
        occursEvery: { 
          type: 'object', 
          properties: { 
            //TODO check for 24 and 59
            intervalType: { enum: ['minute', 'hour'] },
            interval: {type: 'integer', minimum: 0},
          }
        },
      },
      additionalProperties: false
    }
  }
}

module.exports.scheduleSchemaWeekly = {
  $id: "Weekly",
  type: 'object', 
  properties: { 
    eachNWeek: {type: 'integer', minimum: 1},
    dayOfWeek: {
      type: 'array',
      uniqueItems: true,
      items: { enum: ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'] },
      additionalItems: false
    },
    dailyFrequency: {type: 'object'}
  },
  additionalProperties: false
};

module.exports.scheduleSchemaMonthly = {
  $id: "Monthly",
  type: 'object', 
  properties: { 
    month: {
      type: 'array',
      uniqueItems: true,
      items: { enum: ['jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec'] },
      additionalItems: false
    },
    //TODO check feb and short months
    day: {type: 'integer', minimum: 1, maximum: 31},
    dailyFrequency: {type: 'object'}
  },
  additionalProperties: false
};
