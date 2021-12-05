import config from "../config/config";
import index from "../routes/index";
import * as util from "../tools/util";
import session from "express-session";
import cors from "cors";

//TODO separate PROD and DEBUG runs with "const isProduction = process.env.NODE_ENV === 'production'";
const app = util.expressInstance();
app.use(cors(config.cors));
app.use(session(config.session));
import passportConfig from "../config/passport";
passportConfig();

//Swagger
//TODO bring more clarity and details to swagger
import swaggerUi from "swagger-ui-express";
import swaggerDocument from "../swagger.json";
app.use("/api-docs", swaggerUi.serve, swaggerUi.setup(swaggerDocument));

//Setup all routes in this function
index(app);

export default app;
