/**
 * ESLint для ванільного проєкту (глобалі з index.html).
 * Клас StorageManager збігається з ідеєю Web API — no-redeclare залишаємо вимкненим для js/**.
 */

import globals from 'globals';

export default [
  {
    ignores: [
      'node_modules/**',
      '_site/**',
      '.git/**',
      '.project/**',
      '.chrome-*/**',
      'coverage/**',
      'dist/**',
      'build/**',
      'android/**',
      'android/app/src/main/assets/**',
    ],
  },
  {
    files: ['js/**/*.js'],
    languageOptions: {
      ecmaVersion: 'latest',
      sourceType: 'script',
      globals: globals.browser,
    },
    rules: {
      'no-debugger': 'error',
      // Без модулів клас «використовується» з інших файлів — per-file аналіз дає сотні хибних спрацьовувань.
      'no-unused-vars': 'off',
      eqeqeq: ['warn', 'smart'],
      'no-var': 'warn',
      'prefer-const': 'warn',
      'no-redeclare': 'off',
    },
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
