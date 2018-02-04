// routes/index.js
const jobRoutes = require('./job_routes');
const stepRoutes = require('./step_routes');
module.exports = function(app, dbclient) {
  jobRoutes(app, dbclient);
  stepRoutes(app, dbclient);
  // Тут, позже, будут и другие обработчики маршрутов 
};