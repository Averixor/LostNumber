// Runtime environment, debug tiers, ErrorHandler configuration.
(function () {
  const host = (window.location.hostname || '').toLowerCase();
  const isLocalHost =
    host === 'localhost' || host === '127.0.0.1' || host === '[::1]' || host.endsWith('.local');

  /** @type {'off' | 'dev' | 'full'} */
  let debugMode = 'off';
  let persisted = null;
  try {
    persisted = localStorage.getItem('lostnumber_debug');
  } catch (_) {}

  try {
    const u = new URL(window.location.href);
    const d = (u.searchParams.get('debug') || '').toLowerCase();
    const devParam = u.searchParams.get('dev');

    if (d === '0' || d === 'off' || d === 'false') {
      debugMode = 'off';
    } else if (d === 'full' || d === '2' || d === 'senior' || d === 'all') {
      debugMode = 'full';
    } else if (d === '1' || d === 'dev' || d === 'true' || devParam === '1') {
      debugMode = 'dev';
    } else if (persisted === 'full') {
      debugMode = 'full';
    } else if (persisted === 'dev' || persisted === '1') {
      debugMode = 'dev';
    } else if (isLocalHost) {
      debugMode = 'dev';
    }
  } catch (_) {
    if (persisted === 'full') debugMode = 'full';
    else if (persisted === 'dev' || persisted === '1') debugMode = 'dev';
    else if (isLocalHost) debugMode = 'dev';
  }

  const isDev = debugMode !== 'off';
  const isDebugFull = debugMode === 'full';
  const isProd = !isDev;

  window.AppEnv = {
    debugMode,
    isDev,
    isDebugFull,
    isProd,
  };

  try {
    const root = document.documentElement;
    root.classList.remove('debug-dev', 'debug-full');
    if (isDebugFull) {
      root.classList.add('debug-full');
      root.setAttribute('data-ln-debug', 'full');
    } else if (debugMode === 'dev') {
      root.classList.add('debug-dev');
      root.setAttribute('data-ln-debug', 'dev');
    } else {
      root.setAttribute('data-ln-debug', 'off');
    }
  } catch (_) {}

  window.ErrorHandlerConfig = {
    showUserMessages: true,
    logToConsole: isDev,
    collectStackTraces: true,
    maxErrorsPerMinute: isDebugFull ? 250 : isDev ? 120 : 50,
    errorHistorySize: isDebugFull ? 300 : 100,
    onErrorReport(errorData) {
      try {
        if (!isDev && navigator.sendBeacon && window.ANALYTICS_ENDPOINT) {
          const important = ['fatal', 'runtime', 'resource', 'promise', 'game_logic'];
          if (important.includes(errorData.meta?.type)) {
            const report = {
              id: errorData.id,
              type: errorData.meta?.type,
              message: (errorData.message || '').substring(0, 200),
              timestamp: errorData.timestamp,
              url: window.location.href,
            };
            navigator.sendBeacon(
              window.ANALYTICS_ENDPOINT + '/error',
              new Blob([JSON.stringify(report)], { type: 'application/json' }),
            );
          }
        }
      } catch (_) {}
    },
  };

  if (isDebugFull) {
    try {
      console.info(
        '%c[LostNumber] DEBUG FULL (senior)%c — ?debug=full | localStorage lostnumber_debug=full | Ctrl+D панель',
        'color:#7cfc00;font-weight:bold',
        'color:#aaa;font-weight:normal',
      );
    } catch (_) {}
  } else if (debugMode === 'dev') {
    try {
      console.info(
        '%c[LostNumber] DEBUG DEV%c — ?debug=1 або localhost',
        'color:#4fc3f7',
        'color:#888',
      );
    } catch (_) {}
  }
})();
