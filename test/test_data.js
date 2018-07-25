var mongo = require('mongodb');

//job test data preparation
module.exports.job = {
    name: 'job',
    description: 'job description',
    enabled: true,
    steps: [
        {
            name: 'step1',
            enabled: true,      
            connection: new mongo.ObjectID('0a9296f2496698264c23e180'),
            database: 'database',
            command: 'command',
            retryAttempts: {number: 1, interval: 5},
            onSucceed: 'gotoNextStep',
            onFailure: 'quitWithFailure'
        },        
        {
            name: 'step2',
            enabled: true,      
            connection: new mongo.ObjectID('0a9296f2496698264c23e180'),
            database: 'database',
            command: 'command',
            retryAttempts: {number: 1, interval: 5},
            onSucceed: 'gotoNextStep',
            onFailure: {gotoStep: 1}
        }  
    ],
    schedules: [
        {
            name: 'weekly',
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
    description: 'job description',
    enabled: true,
    steps: [
        {
            name: 'step1',
            enabled: true,      
            connection: new mongo.ObjectID('0a9296f2496698264c23e180'),
            database: 'database',
            command: 'command',
            retryAttempts: {number: 1, interval: 5},
            onSucceed: 'gotoNextStep',
            onFailure: 'quitWithFailure'
        },        
        {
            name: 'step2',
            enabled: true,      
            connection: new mongo.ObjectID('0a9296f2496698264c23e180'),
            database: 'database',
            command: 'command',
            retryAttempts: {number: 1, interval: 5},
            onSucceed: 'gotoNextStep',
            onFailure: {gotoStep: 1}
        }  
    ],
    schedules: [
        {
            name: 'weekly',
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
    description: 'job description',
    enabled: true,
    steps: [
        {
            name: 'step1',
            enabled: true,      
            connection: new mongo.ObjectID('0a9296f2496698264c23e180'),
            database: 'database',
            command: 'command',
            retryAttempts: {number: 1, interval: 5},
            onSucceed: 'gotoNextStep',
            onFailure: 'quitWithSuccess'
        }
    ],
    schedules: [
        {
            name: 'weekly',
            enabled: true,
            startDateTime: '2018-01-31T20:54:23.071Z',
            eachNWeek: 1,
            dayOfWeek: ['mon', 'wed', 'fri'],
            dailyFrequency: { occursOnceAt: '11:11:11'}
        },
        {
            name: 'dailyOnce',
            enabled: true,
            startDateTime: '2018-01-31T20:54:23.071Z',
            eachNDay: 1,
            dailyFrequency: { occursOnceAt: '11:11:11'}
        }
    ]  
},
{
    name: 'no steps, no schedules, nothing',
    description: 'job description',
    enabled: true
},
{
    name: 'only schedule',
    description: 'job description',
    enabled: true,
    schedules: [
        {
            name: 'monthly',
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
module.exports.step = {
    name: 'step',
    enabled: true,      
    connection: new mongo.ObjectID('0a9296f2496698264c23e180'),
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
//schedule test data preparation
module.exports.oneTimeSchedule = {
    name: 'oneTime',
    enabled: true,
    oneTime: '2018-01-31T20:54:23.071Z'
};
module.exports.dailyScheduleOnce = {
    name: 'dailyOnce',
    enabled: true,
    startDateTime: '2018-01-31T20:54:23.071Z',
    eachNDay: 1,
    dailyFrequency: { occursOnceAt: '11:11:11'}
};
module.exports.dailyScheduleEvery = {
    name: 'dailyEvery',
    enabled: true,
    startDateTime: '2018-01-31T20:54:23.071Z',
    eachNDay: 1,
    dailyFrequency: { start: '11:11:11', occursEvery: {intervalValue: 1, intervalType: 'minute'}}
};
module.exports.weeklySchedule = {
    name: 'weekly',
    enabled: true,
    startDateTime: '2018-01-31T20:54:23.071Z',
    eachNWeek: 1,
    dayOfWeek: ['mon', 'wed', 'fri'],
    dailyFrequency: { occursOnceAt: '11:11:11'}
};
module.exports.monthlySchedule = {
    name: 'monthly',
    enabled: true,
    startDateTime: '2018-01-31T20:54:23.071Z',
    month: ['jan', 'jul'],
    day: 1,
    dailyFrequency: { start: '11:11:11', occursEvery: {intervalValue: 1, intervalType: 'minute'}}
};
//utils validation test data
module.exports.validTime = '11:11:11';
module.exports.invalidTimes = ['aa:11:11', '24:11:11', '11:60:11', '11:77:aa', '25:aa:64', 'aaaa']

module.exports.validDateTime = '2015-03-25T12:00:00Z';
module.exports.invalidDateTimes = ['2015-aa-25T12:00:00Z', '2015-13-25T12:00:00Z', '2015-03-32T12:00:00Z', '2015032512:00:00Z', 'aaa']
