const passport = require('passport');
const LocalStrategy = require('passport-local');
const Users = require('../app/schemas/user')
const labels = require('../config/message_labels')('en');

passport.use(new LocalStrategy({
  usernameField: 'user[email]',
  passwordField: 'user[password]',
}, (email, password, done) => {
  Users.findOne({ email })
    .then((user) => {
      if(!user || !user.validatePassword(password)) {
        return done(null, false, { error: labels.user.incorrectPasswordOrEmail });
      }
      return done(null, user);
    }).catch(done);
}));