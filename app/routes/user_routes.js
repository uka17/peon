// routes/user_routes.js
const Users = require('../schemas/user');
const passport = require('passport');
const auth = require('../tools/auth');
let ver = '/v1.0';

module.exports = function(app) {
  //POST new user route (optional, everyone has access)
  app.post(ver + '/users', auth.optional, (req, res, next) => {
    const { body: { user } } = req;

    if(!user.email) {
      return res.status(422).json({
        errors: {
          email: 'is required',
        },
      });
    }

    if(!user.password) {
      return res.status(422).json({
        errors: {
          password: 'is required',
        },
      });
    }

    const finalUser = new Users(user);

    finalUser.setPassword(user.password);

    return finalUser.save()
      .then(() => res.json({ user: finalUser.toAuthJSON() }));
  });

  //POST login route (optional, everyone has access)
  app.post(ver + '/users/login', auth.optional, (req, res, next) => {
    const { body: { user } } = req;

    if(!user.email) {
      return res.status(422).json({
        errors: {
          email: 'is required',
        },
      });
    }

    if(!user.password) {
      return res.status(422).json({
        errors: {
          password: 'is required',
        },
      });
    }

    return passport.authenticate('local', { session: false }, (err, passportUser, info) => {
      if(err) {
        return next(err);
      }

      if(passportUser) {
        const user = passportUser;
        user.token = passportUser.generateJWT();

        return res.json({ user: user.toAuthJSON() });
      }

      return status(400).info;
    })(req, res, next);
  });

  //GET current route (required, only authenticated users have access)
  app.get(ver + '/users/current', auth.required, (req, res, next) => {
    const { payload: { id } } = req;

    return Users.findById(id)
      .then((user) => {
        if(!user) {
          return res.sendStatus(400);
        }

        return res.json({ user: user.toAuthJSON() });
      });
  });
}
