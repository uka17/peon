//job test data preparation
module.exports.job = {
    name: 'job',
    description: 'job description',
    enabled: true,
    steps: []  
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
            connection: {},
            database: 'database',
            command: 'command',
            retryAttempts: {number: 1, interval: 5},
            onSucceed: 'gotoNextStep',
            onFailure: 'quitWithFailure'
        },        
        {
            name: 'step2',
            enabled: true,      
            connection: {},
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
            connection: {},
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
            eachNWeek: 1,
            dayOfWeek: ['mon', 'wed', 'fri'],
            dailyFrequency: { occursOnceAt: '11:11:11'}
        },
        {
            name: 'dailyOnce',
            enabled: true,
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
    connection: {},
    database: 'database',
    command: 'command',
    retryAttempts: {number: 1, interval: 5},
    onSucceed: 'quitWithFailure',
    onFailure: 'quitWithFailure'
};
//schedule test data preparation
module.exports.oneTimeSchedule = {
    name: 'oneTime',
    enabled: true,
    oneTime: '2018-01-31T20:54:23.071Z'
};
module.exports.dailyScheduleOnce = {
    name: 'dailyOnce',
    enabled: true,
    eachNDay: 1,
    dailyFrequency: { occursOnceAt: '11:11:11'}
};
module.exports.dailyScheduleEvery = {
    name: 'dailyEvery',
    enabled: true,
    eachNDay: 1,
    dailyFrequency: { start: '11:11:11', occursEvery: {intervalValue: 1, intervalType: 'minute'}}
};
module.exports.weeklySchedule = {
    name: 'weekly',
    enabled: true,
    eachNWeek: 1,
    dayOfWeek: ['mon', 'wed', 'fri'],
    dailyFrequency: { occursOnceAt: '11:11:11'}
};
module.exports.monthlySchedule = {
    name: 'monthly',
    enabled: true,
    month: ['jan', 'jul'],
    day: 1,
    dailyFrequency: { start: '11:11:11', occursEvery: {intervalValue: 1, intervalType: 'minute'}}
};
//utils validation test data
module.exports.validTime = '11:11:11';
module.exports.invalidTimes = ['aa:11:11', '24:11:11', '11:60:11', '11:77:aa', '25:aa:64', 'aaaa']

module.exports.validDateTime = '2015-03-25T12:00:00Z';
module.exports.invalidDateTimes = ['2015-aa-25T12:00:00Z', '2015-13-25T12:00:00Z', '2015-03-32T12:00:00Z', '2015032512:00:00Z', 'aaa']
