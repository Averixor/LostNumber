// Runtime environment and ErrorHandler configuration.
(function () {
  const isDev =
    window.location.hostname.includes('localhost') ||
    window.location.hostname.includes('127.0.0.1') ||
    window.location.search.includes('dev=1');

  window.AppEnv = { isDev, isProd: !isDev };

  window.ErrorHandlerConfig = {
    showUserMessages: true,
    logToConsole: isDev,
    collectStackTraces: true,
    maxErrorsPerMinute: 50,
    errorHistorySize: 100,
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
              new Blob([JSON.stringify(report)], { type: 'application/json' })
            );
          }
        }
      } catch (_) {}
    },
  };
})();
