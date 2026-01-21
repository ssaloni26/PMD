module.exports = {
    overrides: [
      {
        files: ['**/__tests__/**/*.js', '**/*.test.js'],
        settings: {
          jest: {
            version: 29  // Explicitly set Jest version
          }
        },
        rules: {
          'jest/no-deprecated-functions': 'off'  // Disable the problematic rule for test files
        }
      }
    ]
  };