module.exports = {
  //Intro
  //Tavic-CI and local DEV doesn't contain any vars, so both will use localhost:8080 and local PostgreSQL. Heroku will use it's own services via process.env
  //===Databases
  //=Local Linux setting
  useDBSSL: process.env.DBSSL || false,
  postgresConnectionString: process.env.DATABASE_URL || 'postgresql://postgres:255320@172.18.0.2:5432/peon',
  mongoConnectionString: process.env.MONGO_URL || 'mongodb://admin:255320@172.18.0.3:27017/?authSource=admin',
  //=Local Windows setting
  //useDBSSL: process.env.DBSSL || false,
  //postgresConnectionString: process.env.DATABASE_URL || 'postgresql://postgres:255320@localhost:5432/peon',
  //mongoConnectionString: process.env.MONGO_URL || 'mongodb://admin:255320@localhost:27017/?authSource=admin',
  //=Remote Heroku setting
  //useDBSSL: true,
  //postgresConnectionString: 'postgres://lkabdjtptaesng:54cb77ee2d4cdec376f9ab21a0b1b0d1ef988f995291fab17b0af7ba7c12c759@ec2-54-217-234-157.eu-west-1.compute.amazonaws.com:5432/de61oteg9ukstn',
  //===Application
  port: process.env.PORT || 8080,
  test_host: "http://localhost:8080/v1.0",
  runTolerance: 1, //minutes
  cors: { origin: 'http://localhost:9000' },
  //ms
  runInterval: 1000, //milliseconds
  //===Service users
  user: "dummy",
  systemUser: "system",
  testUser: "testBot",
  emergencyUser: "er",
  //===System settings
  logLevel: "info",
  enableDebugOutput: true,
  //===Cookie and session
  session: { 
    secret: 'biteme', 
    cookie: { maxAge: 60000 }, //milliseconds
    resave: false, 
    saveUninitialized: false 
  },
  //===JWT
  JWT: {
    secret: 'rick',
    maxAge:  60 //days
  }
};