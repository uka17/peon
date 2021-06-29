// server.js
const config = require('./config/config');
const index = require('./app/routes/index');    
const app = require('./app/tools/util').expressInstance();
const session = require('express-session');
const dbclient = require('./app/tools/db');
const main = require('./app/engines/main');
const log = require('./log/dispatcher');
const cors = require('cors');
const mongoose = require('mongoose');

//TODO separate PROD and DEBUG runs with "const isProduction = process.env.NODE_ENV === 'production'";

app.use(cors({
  origin: 'http://localhost:9000'
}));

//Auth DB momgoose configuration
app.use(session({ secret: config.secret, cookie: { maxAge: config.cookieMaxAge }, resave: false, saveUninitialized: false }));
mongoose.connect(config.mongoConnectionString, { useNewUrlParser: true, useUnifiedTopology: true });
mongoose.set('debug', config.enableDebugOutput)

//Configure local strategy for passport.js before any routing configuration
require('./config/passport');

//Setup all routes in this function
index(app, dbclient);

//Startup
app.listen(config.port, () => {
  log.info(`We are live on ${config.port}.`);
});

//Main loop
setInterval(main.run, 1000, config.runTolerance);

//Startup actions
main.updateOverdueJobs();
main.resetAllJobsStatuses();

