// routes/user_routes.js
const userEngine = require("../engines/user");
let User = require("../schemas/user");
const passport = require("passport");
const auth = require("../tools/auth");
const config = require("../../config/config");
const util = require("../tools/util");
const labels = require("../../config/message_labels")("en");
let ver = "/v1.0";

module.exports = function (app) {
  //Register user
  app.post(ver + "/users", auth.optional, async (req, res, next) => {
    try {
      const {
        body: { user },
      } = req;
      if (!user.email) {
        return res.status(422).json({ error: labels.user.emailRequired });
      }
      if (!user.email.match(config.emailRegExp)) {
        return res
          .status(422)
          .json({ error: labels.user.emailFormatIncorrect });
      }
      if (await userEngine.getUserByEmail(user.email)) {
        return res.status(422).json({ error: labels.user.alreadyExists });
      }

      if (!user.password) {
        return res.status(422).json({ error: labels.user.passwordRequired });
      }

      if (!user.password.match(config.passwordRegExp)) {
        return res
          .status(422)
          .json({ error: labels.user.passwordFormatIncorrect });
      }

      const finalUser = new User(user.email);
      finalUser.setPassword(user.password);
      return userEngine
        .createUser(
          finalUser.email,
          finalUser.hash,
          finalUser.salt,
          config.user
        )
        .then((createdUser) => {
          finalUser.id = createdUser.id;
          res.status(201).json({ user: finalUser.toAuthJSON() });
        })
        .catch(async function (e) {
          /* istanbul ignore next */
          let logId = await util.logServerError(e, config.user);
          /* istanbul ignore next */
          res
            .status(500)
            .send({ error: labels.common.debugMessage, logId: logId });
        });
    } catch (e) {
      /* istanbul ignore next */
      let logId = await util.logServerError(e, config.user);
      /* istanbul ignore next */
      res.status(500).send({ error: labels.common.debugMessage, logId: logId });
    }
  });

  //Login user
  app.post(ver + "/users/login", auth.optional, async (req, res, next) => {
    try {
      // Just not to forget: const user = req.body.user;
      const {
        body: { user },
      } = req;

      if (!user.email) {
        return res.status(422).json({ error: labels.user.emailRequired });
      }

      if (!user.email.match(config.emailRegExp)) {
        return res
          .status(422)
          .json({ error: labels.user.emailFormatIncorrect });
      }

      if (!user.password) {
        return res.status(422).json({ error: labels.user.passwordRequired });
      }
      // In fact route returns result of callback
      return passport.authenticate(
        "local",
        { session: false },
        async (err, passportUser, info) => {
          if (err) {
            /* istanbul ignore next */
            let logId = await util.logServerError(err, config.user);
            /* istanbul ignore next */
            res
              .status(500)
              .send({ error: labels.common.debugMessage, logId: logId });
          }

          if (passportUser) {
            const user = passportUser;
            user.token = passportUser.generateJWT();

            return res.status(200).json({ user: user.toAuthJSON() });
          }

          return res
            .status(400)
            .json({ error: labels.user.incorrectPasswordOrEmail });
        }
      )(req, res, next);
    } catch (e) {
      /* istanbul ignore next */
      let logId = await util.logServerError(e, config.user);
      /* istanbul ignore next */
      res.status(500).send({ error: labels.common.debugMessage, logId: logId });
    }
  });

  //Get current user
  app.get(ver + "/users/current", auth.required, (req, res, next) => {
    const {
      payload: { id },
    } = req;
    if (!id) return res.status(404).json({ error: labels.user.notFound });
    return userEngine
      .getUserById(id)
      .then((user) => {
        if (!user) {
          return res.status(404).json({ error: labels.user.notFound });
        }
        let currentUser = new User(user.email);
        currentUser.hash = user.hash;
        currentUser.salt = user.salt;
        currentUser.id = user.id;

        return res.status(200).json({ user: currentUser.toAuthJSON() });
      })
      .catch(async function (e) {
        /* istanbul ignore next */
        let logId = await util.logServerError(e, config.user);
        /* istanbul ignore next */
        res
          .status(500)
          .send({ error: labels.common.debugMessage, logId: logId });
      });
  });
};
