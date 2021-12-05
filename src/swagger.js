const swaggerAutogen = require("swagger-autogen")();

const doc = {
  info: {
    title: "Peon API",
    description: "API for Peon application",
  },
  host: "localhost:8080",
  schemes: ["http"],
};

const outputFile = "./swagger.json";
const endpointsFiles = [
  "./routes/connection_routes.js",
  "./routes/user_routes.js",
  "./routes/dummy_routes.js",
  "./routes/job_routes.js",
];

swaggerAutogen(outputFile, endpointsFiles, doc);
