//job test data preparation
module.exports.jobOK = {
  "name": "Test job",
  "description": "Job created for testing purposes",
  "enabled": true,
  "steps": [
    {
      "name": "step1",
      "enabled": true,
      "order": 1,
      "connection": 203,
      "command": "select \"fnLog_Insert\"(1, 'Potatoes!', 'test')",
      "retryAttempts": {
        "number": 1,
        "interval": 5
      },
      "onSucceed": "gotoNextStep",
      "onFailure": "quitWithFailure"
    },
    {
      "name": "step2",
      "enabled": true,
      "order": 2,
      "connection": 203,
      "command": "select \"fnLog_I2nsert\"(1, 'Tomatoes!', 'test')",
      "retryAttempts": {
        "number": 1,
        "interval": 1
      },
      "onSucceed": "quitWithSuccess",
      "onFailure": "quitWithFailure"
    }
  ],
  "schedules": [
    {
      "name": "schedule1",
      "enabled": true,
      "startDateTime": "2018-01-31T20:55:23.071Z",
      "eachNWeek": 1,
      "dayOfWeek": [
        "mon",
        "tue",
        "wed",
        "thu",
        "fri"
      ],
      "dailyFrequency": {
        "start": "06:00:00",
        "occursEvery": {
          "intervalValue": 5,
          "intervalType": "minute"
        }
      }
    }
  ]
};
module.exports.jobNOK = {
  name: 'job',
  "enabled": true,
  description: 'job description',
  steps: [],
  schedules: [
    {
      name: "schedule1",
      enabled: true,
      startDateTime: '2018-01-31T20:54:23.071Z',
      eachNWeek: 'aaa',
      dayOfWeek: ['mon', 'wed', 'fri'],
      dailyFrequency: { occursOnceAt: '11:11:11'}
    },
    {
      name: "schedule1",
      startDateTime: '2018-01-31T20:54:23.071Z',
      eachNWeek: 1,
      dayOfWeek: ['mon', 'wed', 'fri'],
      dailyFrequency: { occursOnceAt: '11:11:11'}
    }
  ]  
};
module.exports.jobTestCaseOK = [
  {
    name: '2 steps 1 schedule',
    "enabled": true,
    description: 'job description',
    steps: [
      {
        name: 'step1',
        enabled: true,    
        order: 1,  
        connection: 1,
        command: 'command',
        retryAttempts: {number: 1, interval: 5},
        onSucceed: 'gotoNextStep',
        onFailure: 'quitWithFailure'
      },        
      {
        name: 'step2',
        enabled: true,
        order: 2,        
        connection: 1,
        command: 'command',
        retryAttempts: {number: 1, interval: 5},
        onSucceed: 'gotoNextStep',
        onFailure: {gotoStep: 1}
      }  
    ],
    schedules: [
      {
        name: "schedule1",
        enabled: true,
        startDateTime: '2018-01-31T20:54:23.071Z',
        eachNWeek: 1,
        dayOfWeek: ['mon', 'wed', 'fri'],
        dailyFrequency: { occursOnceAt: '11:11:11'}
      }
    ]  
  },
  {
    name: '1 step 2 schedules',
    "enabled": true,
    description: 'job description',
    steps: [
      {
        name: 'step1',
        order: 1,  
        enabled: true,      
        connection: 1,
        command: 'command',
        retryAttempts: {number: 1, interval: 5},
        onSucceed: 'gotoNextStep',
        onFailure: 'quitWithSuccess'
      }
    ],
    schedules: [
      {
        name: "schedule1",
        enabled: true,
        startDateTime: '2018-01-31T20:54:23.071Z',
        eachNWeek: 1,
        dayOfWeek: ['mon', 'wed', 'fri'],
        dailyFrequency: { occursOnceAt: '11:11:11'}
      },
      {
        name: "schedule2",
        enabled: true,
        startDateTime: '2018-01-31T20:54:23.071Z',
        eachNDay: 1,
        dailyFrequency: { occursOnceAt: '11:11:11'}
      }
    ]  
  },
  {
    name: 'no steps, no schedules, nothing',
    "enabled": true,
    description: 'job description'
  },
  {
    name: 'only schedule',
    "enabled": true,
    description: 'job description',
    schedules: [
      {
        name: "schedule1",
        enabled: true,
        startDateTime: '2018-01-31T20:54:23.071Z',
        month: ['jan', 'jul'],
        day: 1,
        dailyFrequency: { start: '11:11:11', occursEvery: {intervalValue: 1, intervalType: 'minute'}}
      }
    ]  
  }
];


module.exports.stepList = [
  {
    "name": "step1",
    "order": 2
  },
  {
    "name": "step2",
    "order": 1
  },
  {
    "name": "step3",
    "order": 99
  },
  {
    "name": "step4",
    "order": 3
  },
  {
    "name": "step5",
    "order": 2
  },
  {
    "name": "step6",
    "order": 5
  },
  {
    "name": "step7",
    "order": 4
  }                
];
//step test data preparation
module.exports.stepOK = {
  name: 'step',
  enabled: true,
  order: 1,      
  connection: 1,
  command: 'command',
  retryAttempts: {number: 1, interval: 5},
  onSucceed: 'quitWithFailure',
  onFailure: 'quitWithFailure'
};
//connection test data
module.exports.connectionOK = {
  name: 'test_connection',
  host: '127.0.0.1',
  port: 8080,
  database: 'database',    
  enabled: true,      
  login: 'user',
  password: 'password',
  type: 'mongodb'
};
module.exports.connectionNOK = [
  {
    name: 1,
    host: '127.0.0.1',
    port: 8080,
    enabled: true,      
    login: 'user',
    password: 'password',
    type: 'mongodb'
  },
  {
    name: true,
    host: '127.0.0.1',
    port: 8080,
    enabled: true,      
    login: 'user',
    password: 'password',
    type: 'mongodb'
  },
  {
    name: 'test_connection',
    host: 123,
    port: 8080,
    enabled: true,      
    login: 'user',
    password: 'password',
    type: 'mongodb'
  },
  {
    name: 'test_connection',
    host: '127.0.0.1',
    port: 8080,
    enabled: 777,      
    login: 'user',
    password: 'password',
    type: 'mongodb'
  },
  {
    name: 'test_connection',
    host: '127.0.0.1',
    port: 8080,
    enabled: true,      
    login: 123,
    password: 'password',
    type: 'zzzz'
  },       
  {
    name: 'test_connection',
    host: '127.0.0.1',
    port: 8080,
    enabled: true,      
    login: 'user',
    password: 'password',
    type: 'zzzz'
  }                
];
//testHelper
module.exports.testHelperCorrectObject = {
  string: 'string_test',
  number: 123.123,
  integer: 123,
  boolean: true,
  array: [1, 2, 3],
  object: {},
  enum: 'enum'
};

module.exports.execution = {
  connection:   {
    "name": "Psg-conn",
    "host": "172.17.0.2",
    "port": 5432,
    "enabled": true,
    "login": "postgres",
    "password": "255320",
    "type": "postgresql",
    "database": "peon"
  },
  job: {
    "name": "Test job",
    "description": "Job created for testing massive execution",
    "enabled": true,
    "steps": [
      {
        "name": "Inserting text into abyss",
        "enabled": true,
        "order": 1,
        "connection": null,
        "command": "INSERT INTO public.\"sysAbyss\"(\"text\", \"number\", \"json\") VALUES('insert_value', 1, null);",
        "retryAttempts": {
          "number": 1,
          "interval": 1
        },
        "onSucceed": "gotoNextStep",
        "onFailure": "quitWithFailure"
      }
    ],
    "schedules": [
      {
        "eachNDay": 1,
        "name": "1 per minute",
        "enabled": true,
        "startDateTime": "2021-05-31T21:00:00.000Z",
        "dailyFrequency": {
          "start": "00:00:00",
          "end": "23:00:00",
          "occursEvery": {
            "intervalValue": 1,
            "intervalType": "minute"
          }
        }
      }
    ]
  }
}