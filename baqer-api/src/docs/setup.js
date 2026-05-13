const swaggerUi = require('swagger-ui-express');
const openapi = require('./openapi');

function setup(app) {
  app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(openapi, { explorer: true }));
}

module.exports = setup;

//gg