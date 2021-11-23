import uniTest from "./universal_route_test";
import connectionRoute from "../../app/routes/connection_routes";
const connectionTestObject = require("../data/application").connectionOK;

uniTest(
  "/v1.0/connections",
  connectionRoute,
  connectionTestObject,
  "host",
  "string",
  "connection"
);
