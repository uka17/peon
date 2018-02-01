// routes/index.js
const jobRoutes = require('./job_routes');
const stepRoutes = require('./step_routes');
module.exports = function(app, client) {
  jobRoutes(app, client);
  stepRoutes(app, client);
  // Тут, позже, будут и другие обработчики маршрутов 
};