/* eslint-disable no-undef */

const request = require("supertest");
var assert  = require('chai').assert;
var labels = require('../../config/message_labels')('en');    
let config = require('../../config/config');
config.user = 'testRobot';
const user = require('../data/users')
var app = require('../../app/init/setup').app;
var mongo = require('../../app/init/setup').mongoose;
const Users = require('../../app/schemas/user');
const registerUrl = '/v1.0/users';
const loginUrl = '/v1.0/users/login';
const currentUrl = '/v1.0/users/current';
const { nanoid } = require('nanoid');

function newUser() {
  let clonedUser = JSON.parse(JSON.stringify(user.usersOK.mickey));
  clonedUser.email += nanoid();
  return clonedUser;
}

testUser = newUser();

describe('1 auth unit tests', function() {
  describe('sign up', function() {
    it(`1.1 register new user OK`, (done) => {                        
      request(app)
        .post(registerUrl)            
        .send({ user: testUser })
        .set('Accept', 'application/json')
        .end(function(err, res) { 
          assert.equal(res.status, 201);
          assert.equal(res.body.user.email, testUser.email);
          assert.hasAllKeys(res.body.user, ['email', '_id', 'token']);
          done();
        })
    });

    it(`1.2 register new user, email already taken`, (done) => {                        
      let duplicatedUser = newUser();
      //Register first time
      request(app)
        .post(registerUrl)            
        .send({ user: duplicatedUser })
        .set('Accept', 'application/json')
        .end(function(err, res) { 
          assert.equal(res.status, 201);
          assert.equal(res.body.user.email, duplicatedUser.email);
          assert.hasAllKeys(res.body.user, ['email', '_id', 'token']);
          //Register once again
          request(app)
          .post(registerUrl)            
          .send({ user: duplicatedUser })
          .set('Accept', 'application/json')
          .end(function(err, res) { 
            assert.equal(res.status, 422);
            assert.equal(res.body.error, labels.user.alreadyExists);
            assert.hasAllKeys(res.body, ['error']);
            done();
          })
        })
    });  

    it(`1.3 register new user, no email`, (done) => {                        
      let userNoEmail = newUser();
      delete userNoEmail.email;
      request(app)
        .post(registerUrl)            
        .send({ user: userNoEmail })
        .set('Accept', 'application/json')
        .end(function(err, res) { 
          assert.equal(res.status, 422);
          assert.equal(res.body.error, labels.user.emailRequired);
          assert.hasAllKeys(res.body, ['error']);
          done();
        })
    });    

    it(`1.4 register new user, email format is incorrect`, (done) => {                        
      let userIncorrectEmailFormat = newUser();
      userIncorrectEmailFormat.email = 'myemail'
      request(app)
        .post(registerUrl)            
        .send({ user: userIncorrectEmailFormat })
        .set('Accept', 'application/json')
        .end(function(err, res) { 
          assert.equal(res.status, 422);
          assert.equal(res.body.error, labels.user.emailFormatIncorrect);
          assert.hasAllKeys(res.body, ['error']);
          done();
        })
    });    

    it(`1.5 register new user, password format is incorrect`, (done) => {                        
      let userIncorrectPasswordFormat = newUser();
      userIncorrectPasswordFormat.password = 'password'
      request(app)
        .post(registerUrl)            
        .send({ user: userIncorrectPasswordFormat })
        .set('Accept', 'application/json')
        .end(function(err, res) { 
          assert.equal(res.status, 422);
          assert.equal(res.body.error, labels.user.passwordFormatIncorrect);
          assert.hasAllKeys(res.body, ['error']);
          done();
        })
    });    

    it(`1.6 register new user, no password`, (done) => {                        
      let userNoPassword = newUser();
      delete userNoPassword.password;
      request(app)
        .post(registerUrl)            
        .send({ user: userNoPassword })
        .set('Accept', 'application/json')
        .end(function(err, res) { 
          assert.equal(res.status, 422);
          assert.equal(res.body.error, labels.user.passwordRequired);
          assert.hasAllKeys(res.body, ['error']);
          done();
        })
    });     
  });
  describe('2 login', function() {
    it(`2.1 login user OK`, (done) => {      
      let userLoginOk = newUser();  
      
      //Register
      request(app)
        .post(registerUrl)            
        .send({ user: userLoginOk })
        .set('Accept', 'application/json')
        .end(function(err, res) { 
          assert.equal(res.status, 201);
          assert.equal(res.body.user.email, userLoginOk.email);
          assert.hasAllKeys(res.body.user, ['email', '_id', 'token']);
          //Login
          request(app)
          .post(loginUrl)            
          .send({ user: userLoginOk })
          .set('Accept', 'application/json')
          .end(function(err, res) { 
            console.log(userLoginOk)
            assert.equal(res.status, 200);
            assert.equal(res.body.user.email, userLoginOk.email);
            assert.hasAllKeys(res.body.user, ['email', '_id', 'token']);
            done();
          })
        })
    });

    it(`2.2 login user, no email`, (done) => {                        
      let userNoEmail = newUser();
      delete userNoEmail.email;
      request(app)
        .post(loginUrl)            
        .send({ user: userNoEmail })
        .set('Accept', 'application/json')
        .end(function(err, res) { 
          assert.equal(res.status, 422);
          assert.equal(res.body.error, labels.user.emailRequired);
          assert.hasAllKeys(res.body, ['error']);
          done();
        })
    });    

    it(`2.3 login user, email format is incorrect`, (done) => {                        
      let userIncorrectEmailFormat = newUser();
      userIncorrectEmailFormat.email = 'myemail'
      request(app)
        .post(loginUrl)            
        .send({ user: userIncorrectEmailFormat })
        .set('Accept', 'application/json')
        .end(function(err, res) { 
          assert.equal(res.status, 422);
          assert.equal(res.body.error, labels.user.emailFormatIncorrect);
          assert.hasAllKeys(res.body, ['error']);
          done();
        })
    });    

    it(`2.4 login new user, no password`, (done) => {                        
      let userNoPassword = newUser();
      delete userNoPassword.password;
      request(app)
        .post(loginUrl)            
        .send({ user: userNoPassword })
        .set('Accept', 'application/json')
        .end(function(err, res) { 
          assert.equal(res.status, 422);
          assert.equal(res.body.error, labels.user.passwordRequired);
          assert.hasAllKeys(res.body, ['error']);
          done();
        })
    });     
    
    it(`2.5 login new user failed`, (done) => {                        
      let userLoginFailed = newUser();
      //Register
      request(app)
        .post(registerUrl)            
        .send({ user: userLoginFailed })
        .set('Accept', 'application/json')
        .end(function(err, res) { 
          assert.equal(res.status, 201);
          assert.equal(res.body.user.email, userLoginFailed.email);
          assert.hasAllKeys(res.body.user, ['email', '_id', 'token']);

          userLoginFailed.password = 'corruptedPassword7*';

          //Login
          request(app)
            .post(loginUrl)            
            .send({ user: userLoginFailed })
            .set('Accept', 'application/json')
            .end(function(err, res) { 
              console.log(res.body)
              assert.equal(res.status, 400);
              assert.equal(res.body.error, labels.user.incorrectPasswordOrEmail);
              assert.hasAllKeys(res.body, ['error']);
              done();
            })          
        })
    });    
    //TODO Incorrect token format test  
  });
  describe('3 current', function() {
    it(`3.1 get current user OK`, (done) => {      
      let currentUserOk = newUser();
      //Register
      request(app)
        .post(registerUrl)            
        .send({ user: currentUserOk })
        .set('Accept', 'application/json')
        .end(function(err, res) { 
          assert.equal(res.status, 201);
          assert.equal(res.body.user.email, currentUserOk.email);
          assert.hasAllKeys(res.body.user, ['email', '_id', 'token']);
          let token = res.body.user.token;
          //Current
          request(app)
            .get(currentUrl)            
            .set('Accept', 'application/json')
            .set('Authorization', `Bearer ${token}`)
            .end(function(err, res) { 
              console.log(res.body)
              assert.equal(res.status, 200);
              assert.equal(res.body.user.email, currentUserOk.email);
              assert.hasAllKeys(res.body.user, ['email', '_id', 'token']);
              done();
            })          
        })
    });
    it(`3.2 get current user, token is incorrect`, (done) => {      
      let currentUserOk = newUser();
      //Register
      request(app)
        .post(registerUrl)            
        .send({ user: currentUserOk })
        .set('Accept', 'application/json')
        .end(function(err, res) { 
          assert.equal(res.status, 201);
          assert.equal(res.body.user.email, currentUserOk.email);
          assert.hasAllKeys(res.body.user, ['email', '_id', 'token']);
          let token = 'FBI';
          //Current
          request(app)
            .get(currentUrl)            
            .set('Accept', 'application/json')
            .set('Authorization', `Bearer ${token}`)
            .end(function(err, res) { 
              console.log(res.body)
              assert.equal(res.status, 401);
              assert.equal(res.body.error, labels.user.incorrectToken);
              assert.hasAllKeys(res.body, ['error']);
              done();
            })          
        })
    });    
    it(`3.3 get current user, user no found`, (done) => {      
      const shadowUser = new Users({email: 'shadow', password: 'shadow' });
      const token = shadowUser.generateJWT();
      //Current
      request(app)
        .get(currentUrl)            
        .set('Accept', 'application/json')
        .set('Authorization', `Bearer ${token}`)
        .end(function(err, res) { 
          console.log(res.body)
          assert.equal(res.status, 404);
          assert.equal(res.body.error, labels.user.notFound);
          assert.hasAllKeys(res.body, ['error']);
          done();
        })          
    });        
  });  
  after(function() {
    mongo.connection.close();
  });  
});   

