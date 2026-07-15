/**
 * ESLint for npm tooling scripts under scripts/.
 */

import globals from 'globals';

export default [
  {
    ignores: [
      'node_modules/**',
      '.git/**',
      '.project/**',
      '.chrome-*/**',
      'coverage/**',
      'dist/**',
      'build/**',
      'godot/**',
      'android/**',
    ],
  },
  {
    files: ['**/*.mjs'],
    languageOptions: {
      ecmaVersion: 'latest',
      sourceType: 'module',
      globals: globals.node,
    },
    rules: {
      'no-debugger': 'error',
      'no-unused-vars': [
        'warn',
        {
          argsIgnorePattern: '^_',
          varsIgnorePattern: '^_',
        },
      ],
      eqeqeq: ['warn', 'smart'],
      'no-var': 'warn',
      'prefer-const': 'warn',
    },
  },
];
