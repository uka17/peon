import uniTest from "./universal_route_test";
import jobRoute from "../../app/routes/job_routes";
import testObjects from "../data/application";

uniTest("/v1.0/jobs", jobRoute, testObjects.jobBodyOK, "name", "string", "job");
