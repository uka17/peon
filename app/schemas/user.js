//TODO Move to engines?

const crypto = require("crypto");
const jwt = require("jsonwebtoken");
const config = require("../../config/config");

const User = function (user) {
  this.email = user;

  this.setPassword = function (password) {
    this.salt = crypto.randomBytes(16).toString("hex");
    this.hash = crypto
      .pbkdf2Sync(password, this.salt, 10000, 512, "sha512")
      .toString("hex");
  };

  this.validatePassword = function (password) {
    const hash = crypto
      .pbkdf2Sync(password, this.salt, 10000, 512, "sha512")
      .toString("hex");
    return this.hash === hash;
  };

  this.generateJWT = function () {
    const expirationDate = new Date();
    expirationDate.setDate(expirationDate.getDate() + config.JWT.maxAge);
    return jwt.sign(
      {
        email: this.email,
        id: this.id,
        exp: parseInt(expirationDate.getTime() / 1000, 10),
      },
      config.JWT.secret
    );
  };

  this.toAuthJSON = function () {
    return {
      id: this.id,
      email: this.email,
      token: this.generateJWT(),
    };
  };
};
module.exports = User;
