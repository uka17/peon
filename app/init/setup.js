
const config = require('../../config/config');
const index = require('../../app/routes/index');    
const app = require('../../app/tools/util').expressInstance();
const session = require('express-session');
const dbclient = require('../../app/tools/db');
const log = require('../../log/dispatcher');
const cors = require('cors');
const mongoose = require('mongoose');

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

app.use(cors(config.cors));
app.use(session(config.session));
mongoConnet();
require('../../app/schemas/user');
require('../../config/passport');

//Swagger
const swaggerUi = require('swagger-ui-express');
const swaggerDocument = require('../../swagger.json');
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerDocument));

//Setup all routes in this function
index(app, dbclient);

module.exports.app = app;
module.exports.mongoose = mongoose;