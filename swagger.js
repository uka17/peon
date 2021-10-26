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
  "./app/routes/connection_routes.js",
  "./app/routes/user_routes.js",
  "./app/routes/dummy_routes.js",
  "./app/routes/job_routes.js",
];

swaggerAutogen(outputFile, endpointsFiles, doc);
