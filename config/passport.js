const passport = require("passport");
const LocalStrategy = require("passport-local");
const User = require("../app/schemas/user");
const userEngine = require("../app/engines/user");
const labels = require("../config/message_labels")("en");

passport.use(
  new LocalStrategy(
    {
      usernameField: "user[email]",
      passwordField: "user[password]",
    },
    (email, password, done) => {
      userEngine
        .getUserByEmail(email)
        .then((dbUser) => {
          if (dbUser) {
            let user = new User(dbUser.email);
            user.hash = dbUser.hash;
            user.salt = dbUser.salt;
            user.id = dbUser.id;
            if (!user.validatePassword(password)) {
              return done(null, false, {
                error: labels.user.incorrectPasswordOrEmail,
              });
            }
            return done(null, user);
          } else {
            return done(null, false, {
              error: labels.user.incorrectPasswordOrEmail,
            });
          }
        })
        .catch(done);
    }
  )
);
