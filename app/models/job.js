//models/job.js
var Ajv = require('ajv');

module.exports.jobSchema = {
  $id: "job",
  type: "object",
  properties: {
    name: {type: 'string'},
    description: {type: 'string'},
    enabled: {type: 'boolean'},
    createdOn: {type: 'string', format: 'date'},
    createdBy: {type: 'string'},
    modifiedOn: {type: 'string', format: 'date'},
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
    createdOn: {type: 'string', format: 'date'},
    createdBy: {type: 'string'},
    modifiedOn: {type: 'string', format: 'date'},
    modifiedBy: {type: 'string'}
  },
  additionalProperties: false
};