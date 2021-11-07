import passport from "passport";
import local from "passport-local";
import User from "../app/engines/user";
const labels = require("../config/message_labels")("en");

passport.use(
  new local.Strategy(
    {
      usernameField: "user[email]",
      passwordField: "user[password]",
    },
    (
      email: string,
      password: string,
      done: (error: any, user?: any, options?: local.IVerifyOptions) => void
    ) => {
      User.getByEmail(email)
        .then((dbUser) => {
          if (dbUser) {
            const user = dbUser as User;
            if (!user.validatePassword(password)) {
              return done(null, false, {
                message: labels.user.incorrectPasswordOrEmail,
              });
            }
            return done(null, user);
          } else {
            return done(null, false, {
              message: labels.user.incorrectPasswordOrEmail,
            });
          }
        })
        .catch(done);
    }
  )
);
