module.exports = {
  extends: 'solhint:recommended',
  rules: {
    'compiler-version': ['error', '^0.8.20'],
    'func-visibility': ['warn', { ignoreConstructors: true }],
    'max-line-length': 'off',
    'no-console': 'off',
    'not-rely-on-time': 'warn',
    'quotes': ['error', 'double'],
    'avoid-low-level-calls': 'warn',
    'no-unused-vars': 'error'
  }
};