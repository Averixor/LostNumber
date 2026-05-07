import globals from 'globals';

/**
 * Мінімальний ESLint для проєкту без modules (глобалі з index.html).
 * Клас StorageManager конфліктує з Web API — no-redeclare вимкнено.
 */
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
