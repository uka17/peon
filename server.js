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
require('./config/passport');

async function mongoConnet() {
  try {
    mongoose.set('debug', config.enableDebugOutput);
    await mongoose.connect(config.mongoConnectionString, { useNewUrlParser: true, connectTimeoutMS: 1000 });
  } catch (error) {
    log.error(error);
    process.exit(1);
  }  
}

//TODO separate PROD and DEBUG runs with "const isProduction = process.env.NODE_ENV === 'production'";

app.use(cors({
  origin: 'http://localhost:9000'
}));
app.use(session(config.session));
mongoConnet();
require('./app/schemas/user');

index(app, dbclient);

app.listen(config.port, () => {
  log.info(`We are live on ${config.port}.`);
});

//Main loop
setInterval(main.run, config.runInterval, config.runTolerance);

//Startup actions
main.updateOverdueJobs();
main.resetAllJobsStatuses();
