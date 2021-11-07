const config = require("../../config/config");
const index = require("../../app/routes/index");
const app = require("../../app/tools/util").expressInstance();
const session = require("express-session");
const dbclient = require("../../app/tools/db");
const cors = require("cors");

//TODO separate PROD and DEBUG runs with "const isProduction = process.env.NODE_ENV === 'production'";

app.use(cors(config.cors));
app.use(session(config.session));
require("../../config/passport");

//Swagger
const swaggerUi = require("swagger-ui-express");
const swaggerDocument = require("../../swagger.json");
app.use("/api-docs", swaggerUi.serve, swaggerUi.setup(swaggerDocument));

//Setup all routes in this function
index(app, dbclient);

module.exports.app = app;
