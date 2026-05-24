(function () {
  'use strict';

  const TRIGGER_ID = 'devModeEasterEgg';
  const REQUIRED_CLICKS = 5;
  const RESET_MS = 2500;

  function isDevToolsAllowed() {
    return (
      typeof window.LN_isDevToolsAllowed === 'function' && window.LN_isDevToolsAllowed() === true
    );
  }

  function hasDevToolsQuery() {
    try {
      const params = new URLSearchParams(window.location.search || '');
      return (
        params.get('dev') === '1' ||
        params.has('cheats') ||
        params.get('debug') === '1' ||
        params.get('debug') === 'full'
      );
    } catch (_) {
      return false;
    }
  }

  function isDevSessionActive() {
    if (!isDevToolsAllowed()) {
      return false;
    }
    if (window.__LN_CODES_INSTALLED__) {
      return true;
    }
    if (
      typeof window.LN_isLocalDevEnvironment === 'function' &&
      window.LN_isLocalDevEnvironment()
    ) {
      return true;
    }
    if (window.LN_BUILD_FLAGS && window.LN_BUILD_FLAGS.cheatsEnabled === true) {
      return true;
    }
    return hasDevToolsQuery();
  }

  function buildDevUrl() {
    const url = new URL(window.location.href);
    url.searchParams.set('dev', '1');
    url.searchParams.set('cheats', '1');
    return url.toString();
  }

  function confirmDevMode() {
    return window.confirm(
      'Ви переходите в режим розробника.\n\n' +
        'У цьому режимі будуть доступні тестові функції, чит-панель та debug-можливості.\n\n' +
        'Продовжити?',
    );
  }

  function enterDevMode() {
    if (!isDevToolsAllowed()) {
      return;
    }
    if (!confirmDevMode()) {
      return;
    }
    window.location.href = buildDevUrl();
  }

  function initDevEntry() {
    if (!isDevToolsAllowed()) {
      return;
    }

    const trigger = document.getElementById(TRIGGER_ID);
    if (!trigger) {
      return;
    }

    let clicks = 0;
    let timer = null;

    trigger.addEventListener('click', function (event) {
      clicks += 1;

      clearTimeout(timer);
      timer = setTimeout(function () {
        clicks = 0;
      }, RESET_MS);

      if (clicks < REQUIRED_CLICKS) {
        return;
      }

      event.preventDefault();
      event.stopPropagation();
      clicks = 0;

      if (isDevSessionActive()) {
        if (window.LN_CODES && typeof window.LN_CODES.panel === 'function') {
          window.LN_CODES.panel();
        }
        return;
      }

      enterDevMode();
    });
  }

  window.LN_DEV_ENTRY = {
    enter: enterDevMode,
    isAllowed: isDevToolsAllowed,
    isActive: isDevSessionActive,
  };

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initDevEntry, { once: true });
  } else {
    initDevEntry();
  }
})();
