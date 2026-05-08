/**
 * Мінімальний ESLint для проєкту без modules (глобалі з index.html).
 * Клас StorageManager конфліктує з Web API — no-redeclare вимкнено.
 */

import globals from 'globals';

export default [
  { ignores: ['node_modules/**'] },
  {
    files: ['js/**/*.js'],
    languageOptions: {
      ecmaVersion: 2022,
      sourceType: 'script',
      globals: globals.browser,
    },
    rules: {
      'no-debugger': 'warn',
      'no-redeclare': 'off',
    },
  },
];
