//job test data preparation
module.exports.job = {
    name: 'job',
    description: 'job description',
    enabled: true,
    steps: []  
};
//---
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
//---
//schedule test data preparation
module.exports.oneTimeSchedule = {
    name: 'oneTime',
    enabled: true,
    oneTime: '2018-05-31T20:54:23.071Z'
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
//---