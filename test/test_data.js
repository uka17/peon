//job test data preparation
module.exports.jobOK = {
    "name": "job",
    "enabled": true,
    "description": "job description",
    "steps": [
        {
            "name": "step1",
            "enabled": true,      
            "connection": 1,
            "database": "database",
            "command": "command",
            "retryAttempts": {"number": 1, "interval": 5},
            "onSucceed": "gotoNextStep",
            "onFailure": "quitWithFailure"
        },        
        {
            "name": "step2",
            "enabled": true,      
            "connection": 1,
            "database": "database",
            "command": "command",
            "retryAttempts": {"number": 1, "interval": 5},
            "onSucceed": "gotoNextStep",
            "onFailure": {"gotoStep": 1}
        }  
    ],
    "schedules": [
        {
            "enabled": true,
            "startDateTime": "2018-01-31T20:54:23.071Z",
            "eachNWeek": 1,
            "dayOfWeek": ["mon", "wed", "fri"],
            "dailyFrequency": { "occursOnceAt": "11:11:11"}
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
            enabled: true,
            startDateTime: '2018-01-31T20:54:23.071Z',
            eachNWeek: 'aaa',
            dayOfWeek: ['mon', 'wed', 'fri'],
            dailyFrequency: { occursOnceAt: '11:11:11'}
        },
        {
            enabled: true,
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
            connection: 1,
            database: 'database',
            command: 'command',
            retryAttempts: {number: 1, interval: 5},
            onSucceed: 'gotoNextStep',
            onFailure: 'quitWithFailure'
        },        
        {
            name: 'step2',
            enabled: true,      
            connection: 1,
            database: 'database',
            command: 'command',
            retryAttempts: {number: 1, interval: 5},
            onSucceed: 'gotoNextStep',
            onFailure: {gotoStep: 1}
        }  
    ],
    schedules: [
        {
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
            enabled: true,      
            connection: 1,
            database: 'database',
            command: 'command',
            retryAttempts: {number: 1, interval: 5},
            onSucceed: 'gotoNextStep',
            onFailure: 'quitWithSuccess'
        }
    ],
    schedules: [
        {
            enabled: true,
            startDateTime: '2018-01-31T20:54:23.071Z',
            eachNWeek: 1,
            dayOfWeek: ['mon', 'wed', 'fri'],
            dailyFrequency: { occursOnceAt: '11:11:11'}
        },
        {
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
            enabled: true,
            startDateTime: '2018-01-31T20:54:23.071Z',
            month: ['jan', 'jul'],
            day: 1,
            dailyFrequency: { start: '11:11:11', occursEvery: {intervalValue: 1, intervalType: 'minute'}}
        }
    ]  
}
]
//step test data preparation
module.exports.stepOK = {
    name: 'step',
    enabled: true,      
    connection: 1,
    database: 'database',
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
}
