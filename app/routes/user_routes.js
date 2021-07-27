// routes/user_routes.js
const Users = require('../schemas/user');
const passport = require('passport');
const auth = require('../tools/auth');
const labels = require('../../config/message_labels')('en');
let ver = '/v1.0';

module.exports = function(app) {
  //POST new user route (optional, everyone has access)
  app.post(ver + '/users', auth.optional, (req, res, next) => {
    const { body: { user } } = req;

    if(!user.email) {
      return res.status(422).json({error: labels.user.emailRequired});
    }

    if(!user.password) {
      return res.status(422).json({error: labels.user.passwordRequired});
    }

    const finalUser = new Users(user);

    finalUser.setPassword(user.password);

    return finalUser.save()
      .then(() => res.status(201).json({ user: finalUser.toAuthJSON() }));
  });

  //POST login route (optional, everyone has access)
  app.post(ver + '/users/login', auth.optional, (req, res, next) => {
    const { body: { user } } = req;

    if(!user.email) {
      return res.status(422).json({error: labels.user.emailRequired});
    }

    if(!user.password) {
      return res.status(422).json({error: labels.user.passwordRequired});
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

      return res.status(400).json({error: labels.user.incorrectPasswordOrEmail});
    })(req, res, next);
    
  });

  //GET current route (required, only authenticated users have access)
  app.get(ver + '/users/current', auth.required, (req, res, next) => {
    const { payload: { id } } = req;
    
    return Users.findById(id)
      .then((user) => {
        if(!user) {
          return res.status(404).json({error: 'User not found'});
        }

        return res.json({ user: user.toAuthJSON() });
      });
  });

  //GET current route (required, only authenticated users have access to their own account)
  app.get(ver + '/users/:id', auth.required, (req, res, next) => {
    const id = req.params.id;
    const jwtId = req.payload.id;
    
    return Users.findById(id)
      .then((user) => {
        if(id != jwtId) {
          return res.status(401).json({error: 'User not authorized to view this info'}); 
        } else {
          if(!user) {
            return res.status(404).json({error: 'User not found'});
          }
          return res.json({ user: user.toAuthJSON() });
        }
      });
  });
}
