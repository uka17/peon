import uniTest from "./universal_route_test";
import jobRoute from "../../src/routes/job_routes";
import testObjects from "../data/application";

uniTest("/v1.0/jobs", jobRoute, testObjects.jobBodyOK, "name", "string", "job");
