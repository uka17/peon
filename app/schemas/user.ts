//TODO Move to engines?

import crypto from "crypto";
import jwt from "jsonwebtoken";
import config from "../../config/config";

export default class User {
  public email: string;
  public hash: string;
  public salt: string;
  public id: string;

  constructor(email: string) {
    this.email = email;
  }

  public setPassword = (password: string) => {
    this.salt = crypto.randomBytes(16).toString("hex");
    this.hash = crypto
      .pbkdf2Sync(password, this.salt, 10000, 512, "sha512")
      .toString("hex");
  };

  public validatePassword = (password: string): boolean => {
    const hash = crypto
      .pbkdf2Sync(password, this.salt, 10000, 512, "sha512")
      .toString("hex");
    return this.hash === hash;
  };

  public generateJWT = () => {
    const expirationDate = new Date();
    expirationDate.setDate(expirationDate.getDate() + config.JWT.maxAge);
    return jwt.sign(
      {
        email: this.email,
        id: this.id,
        exp: Math.round(expirationDate.getTime() / 1000),
      },
      config.JWT.secret
    );
  };

  public toAuthJSON = () => {
    return {
      id: this.id,
      email: this.email,
      token: this.generateJWT(),
    };
  };
}
