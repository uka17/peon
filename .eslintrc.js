module.exports = {
  "env": {
    "node": true,
    "commonjs": true,
    "es6": true,
  },
  "extends": "eslint:recommended",
  "globals": {
    "Atomics": "readonly",
    "SharedArrayBuffer": "readonly",
  },
  "parserOptions": {
    "ecmaVersion": 12, // версия стандарта JavaScript. Последний 12 (2021).
    "sourceType": "module", // Позволяет использовать import/export
  },
  "plugins": ["prettier"],
  "rules": {
    "prettier/prettier": "error",
    "indent": ["warn", 2],
    "linebreak-style": ["error", "unix"],
    "semi": ["warn", "always"],
  },
};
