// jest.config.js
module.exports = {
  testEnvironment: 'node',
  coverageDirectory: 'coverage',
  collectCoverageFrom: [
    'src/**/*.js',
    '!src/__tests__/**',
    '!src/server.js'
  ],
  testMatch: ['**/__tests__/**/*.test.js'],
  testTimeout: 10000,
  verbose: true
};
