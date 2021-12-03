import uniTest from "./universal_route_test";
import connectionRoute from "../../app/routes/connection_routes";
import testObjects from "../data/application";

uniTest(
  "/v1.0/connections",
  connectionRoute,
  testObjects.connectionOK,
  "host",
  "string",
  "connection"
);
