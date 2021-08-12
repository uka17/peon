/* eslint-disable no-undef */

const request = require("supertest");
var assert  = require('chai').assert;
var messageBox = require('../../config/message_labels')('en');    
let config = require('../../config/config');
config.user = 'testRobot';
const user = require('../test_data')
var app = require('../../app/init/setup').app;
var mongo = require('../../app/init/setup').mongoose;
const url = '/v1.0/users';

describe('auth unit tests ', function() {

  it.only(`1.1 register new user`, (done) => {                        
    let testUser = JSON.parse(JSON.stringify(user.usersOK.mickey));
    request(app)
      .post(url)            
      .send({ user: testUser })
      .set('Accept', 'application/json')
      .end(function(err, res) { 
        assert.equal(res.status, 201);
        assert.equal(res.body.user.email, testUser.email);
        assert.hasAllKeys(res.body.user, ['email', '_id', 'token']);
        done();
      })
  });

  after(function() {
    mongo.connection.close();
  });


});   

