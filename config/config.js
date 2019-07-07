module.exports = {
    //Intro
    //Tavic-CI and local DEV doesn't contain any vars, so both will use localhost:8080 and local PostgreSQL. Heroku will use it's own services via process.env
    //===Database
    useDBSSL: process.env.DBSSL || false,
    //connectionString: process.env.DATABASE_URL || 'postgresql://postgres:255320@172.17.0.2:5432/peon',
    "connectionString": 'postgres://nvaaifkvsfzpbc:57c563cfd11a6e0040c3db1b84a7774686d4c3aff587c6205c155c69c939a3ef@ec2-54-247-85-251.eu-west-1.compute.amazonaws.com:5432/ddckjterc9mj8r',
    //===Application
    port: process.env.PORT || 8080,
    test_host: "http://localhost:8080/v1.0",    
    user: "test",
    systemUser: "system",
    emergencyUser: "er",
    logLevel: "info",
    enableDebugOutput: true,
    runTolerance: 1
  };