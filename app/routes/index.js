// routes/index.js
const dummyRoutes = require('./dummy_routes');
const jobRoutes = require('./job_routes');
const stepRoutes = require('./step_routes');
module.exports = function(app, dbclient) {
  dummyRoutes(app, dbclient);
  jobRoutes(app, dbclient);
  stepRoutes(app, dbclient);
  // Тут, позже, будут и другие обработчики маршрутов 
};