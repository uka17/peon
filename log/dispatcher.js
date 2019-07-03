// log/dispatcher.js
const logLevel = require('../config/config').logLevel;

const winston = require("winston");
const { combine, timestamp, colorize, printf, logstash} = winston.format;
const Transport = require('winston-transport');

/* istanbul ignore next */
const runFormat = printf(({ level, message, timestamp }) => {
    return `${timestamp} [${level}]: ${message}`;
  });

/* istanbul ignore next */
let peonDBTransport = class peonDBTransport extends Transport {
  constructor(opts) {
    super(opts);
  }

  log(info, callback) {
    setImmediate(() => {
      this.emit('logged', info);
    });

    // Perform the writing to the remote service    
    //---
    //Log stash connect here
    //---
    callback();
  }
};

let debugChannel = winston.createLogger({
  level: logLevel,
  format: combine(    
    colorize({ colors: { info: "blue", error: "red", warning: "orange" } }),
    timestamp(),
    runFormat
  ),
  transports: [
    new winston.transports.File({ filename: "./log/app.log", maxFiles: 10, maxsize: 1024, tailable: true }),
    new winston.transports.Console()
  ]
});
module.exports.debugChannel = debugChannel;

let logstashChannel = winston.createLogger({
  level: logLevel,
  format: combine(    
    timestamp(),
    logstash()
  ),
  transports: [
    new peonDBTransport()
  ]
});
module.exports.logstashChannel = logstashChannel;

/* istanbul ignore next */
module.exports.error = message => {
  debugChannel.error(message);
  logstashChannel.error(message);
}
/* istanbul ignore next */
module.exports.warn = message => {
  debugChannel.warn(message);
  logstashChannel.warn(message);
}
/* istanbul ignore next */
module.exports.info = message => {
  debugChannel.info(message);
  logstashChannel.info(message);
}