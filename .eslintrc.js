module.exports = {
  "env": {
    "node": true,
    "commonjs": true,
    "es6": true,
  },
  "parser": "@typescript-eslint/parser",
  "extends": [
    "eslint:recommended",
    "plugin:@typescript-eslint/recommended",
    "plugin:prettier/recommended",
  ],
  "globals": {
    "Atomics": "readonly",
    "SharedArrayBuffer": "readonly",
  },
  "parserOptions": {
    "ecmaVersion": 12,
    "sourceType": "module",
  },
  "plugins": ["prettier"],
  "rules": {
    "prettier/prettier": "error",
    "indent": ["warn", 2],
    "linebreak-style": ["error", "unix"],
    "semi": ["warn", "always"],
  },
};
