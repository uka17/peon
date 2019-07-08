module.exports = {
    //Intro
    //Tavic-CI and local DEV doesn't contain any vars, so both will use localhost:8080 and local PostgreSQL. Heroku will use it's own services via process.env
    //===Database
    //useDBSSL: process.env.DBSSL || false,
    useDBSSL: true,
    connectionString: process.env.DATABASE_URL || 'postgresql://postgres:255320@172.17.0.2:5432/peon',
    //connectionString: 'postgres://lkabdjtptaesng:54cb77ee2d4cdec376f9ab21a0b1b0d1ef988f995291fab17b0af7ba7c12c759@ec2-54-217-234-157.eu-west-1.compute.amazonaws.com:5432/de61oteg9ukstn',
    //===Application
    port: process.env.PORT || 8080,
    test_host: "http://localhost:8080/v1.0",    
    user: "dummy",
    systemUser: "system",
    emergencyUser: "er",
    logLevel: "info",
    enableDebugOutput: true,
    runTolerance: 1
  };