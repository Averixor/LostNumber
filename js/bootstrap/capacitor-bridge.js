(function initCapacitorBridge() {
  'use strict';

  function isNativeCapacitor() {
    try {
      return !!(
        window.Capacitor &&
        typeof window.Capacitor.isNativePlatform === 'function' &&
        window.Capacitor.isNativePlatform()
      );
    } catch (_) {
      return false;
    }
  }

  if (!isNativeCapacitor()) {
    return;
  }

  window.LN_NATIVE_APP = true;
  document.documentElement.classList.add('ln-native-app');

  function applyStatusBar() {
    if (!window.Capacitor?.Plugins?.StatusBar) {
      return;
    }
    const StatusBar = window.Capacitor.Plugins.StatusBar;
    Promise.resolve()
      .then(() => StatusBar.setOverlaysWebView({ overlay: false }))
      .then(() => StatusBar.setBackgroundColor({ color: '#1b1028' }))
      .then(() => StatusBar.setStyle({ style: 'DARK' }))
      .catch(() => {});
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', applyStatusBar, { once: true });
  } else {
    applyStatusBar();
  }

  document.addEventListener(
    'visibilitychange',
    function () {
      if (document.hidden) {
        if (
          window.game &&
          window.game.screenState === 'game' &&
          typeof window.game.saveGameState === 'function'
        ) {
          window.game.saveGameState();
        }
        return;
      }
      applyStatusBar();
    },
    { passive: true },
  );
})();
