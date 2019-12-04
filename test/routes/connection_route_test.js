var uniTest = require('./universal_route_test');
var connectionRoute = require('../../app/routes/connection_routes');
var connectionTestObject = require('../test_data').connectionOK;

uniTest.testApiRoute('/v1.0/connections', connectionRoute, connectionTestObject, 'host', 'string', 'connection');