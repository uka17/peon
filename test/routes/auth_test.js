/* eslint-disable no-undef */

const request = require("supertest");
var assert  = require('chai').assert;
var labels = require('../../config/message_labels')('en');    
let config = require('../../config/config');
config.user = 'testRobot';
const user = require('../test_data')
var app = require('../../app/init/setup').app;
var mongo = require('../../app/init/setup').mongoose;
const url = '/v1.0/users';
const { nanoid } = require('nanoid');

function newUser() {
  let clonedUser = JSON.parse(JSON.stringify(user.usersOK.mickey));
  clonedUser.email += nanoid();
  return clonedUser;
}

testUser = newUser();

describe('auth unit tests ', function() {

  it.only(`1.1 register new user OK`, (done) => {                        
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

  it.only(`1.2 register new user, email already taken`, (done) => {                        
    request(app)
      .post(url)            
      .send({ user: testUser })
      .set('Accept', 'application/json')
      .end(function(err, res) { 
        assert.equal(res.status, 422);
        assert.equal(res.body.error, labels.user.alreadyExists);
        assert.hasAllKeys(res.body, ['error']);
        done();
      })
  });  

  it.only(`1.3 register new user, no email`, (done) => {                        
    let userIncorrectPasswordFormat = newUser();
    delete userIncorrectPasswordFormat.email;
    request(app)
      .post(url)            
      .send({ user: userIncorrectPasswordFormat })
      .set('Accept', 'application/json')
      .end(function(err, res) { 
        assert.equal(res.status, 422);
        assert.equal(res.body.error, labels.user.emailRequired);
        assert.hasAllKeys(res.body, ['error']);
        done();
      })
  });    

  it.only(`1.4 register new user, email format is incorrect`, (done) => {                        
    let userIncorrectPasswordFormat = newUser();
    userIncorrectPasswordFormat.email = 'myemail'
    request(app)
      .post(url)            
      .send({ user: userIncorrectPasswordFormat })
      .set('Accept', 'application/json')
      .end(function(err, res) { 
        assert.equal(res.status, 422);
        assert.equal(res.body.error, labels.user.emailFormatIncorrect);
        assert.hasAllKeys(res.body, ['error']);
        done();
      })
  });    

  it.only(`1.5 register new user, password format is incorrect`, (done) => {                        
    let userIncorrectPasswordFormat = newUser();
    userIncorrectPasswordFormat.password = 'password'
    request(app)
      .post(url)            
      .send({ user: userIncorrectPasswordFormat })
      .set('Accept', 'application/json')
      .end(function(err, res) { 
        assert.equal(res.status, 422);
        assert.equal(res.body.error, labels.user.passwordFormatIncorrect);
        assert.hasAllKeys(res.body, ['error']);
        done();
      })
  });    

  it.only(`1.6 register new user, no password`, (done) => {                        
    let userIncorrectPasswordFormat = newUser();
    delete userIncorrectPasswordFormat.password;
    request(app)
      .post(url)            
      .send({ user: userIncorrectPasswordFormat })
      .set('Accept', 'application/json')
      .end(function(err, res) { 
        assert.equal(res.status, 422);
        assert.equal(res.body.error, labels.user.passwordRequired);
        assert.hasAllKeys(res.body, ['error']);
        done();
      })
  });     

  after(function() {
    mongo.connection.close();
  });


});   

