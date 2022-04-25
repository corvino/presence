/* eslint-env node */
module.exports = {
  extends: ["eslint:recommended"],
  parserOptions: {
    ecmaVersion: 2017
  },
  env: {
    node: true,
    es2022: true
  },
  rules: {
    semi: ["error", "always", { "omitLastInOneLineBlock": true}],
    quotes: ["error", "double", { avoidEscape: true }],
    "comma-dangle": ["error", "never"],
    "no-unused-vars": ["error", { "argsIgnorePattern": "^_$" }],
    "no-constant-condition": "never"
  },
  settings: {
    react: {
      version: "17.0.2"
    }
  }
};
