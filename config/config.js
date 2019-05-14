module.exports = {
    //Intro
    //Tavic-CI and local DEV doesn't contain any vars, so both will use localhost:8080 and local PostgreSQL. Heroku will use it's own services via process.env
    //Database
    connectionString: 'postgresql://postgres:255320@172.17.0.3:5432/peon',
    //Application
    port: process.env.PORT || 8080,
    test_host: "http://localhost:8080/v1.0",    
    user: "test",
    debugMode: true    
  };