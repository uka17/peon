// routes/index.js
const jobRoutes = require('./job_routes');
module.exports = function(app, client) {
  jobRoutes(app, client);
  // Тут, позже, будут и другие обработчики маршрутов 
};