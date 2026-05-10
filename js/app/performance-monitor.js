// Performance monitor: auto-disable floating background numbers on severe FPS drops.
(function () {
  function dispatchAutoDisable(detail) {
    try {
      window.dispatchEvent(new CustomEvent('lostnumber:floating-numbers-auto-disable', { detail }));
    } catch (e) {
      // ignore
    }
  }

  function startMonitor() {
    // Prefer explicit game instance if available.
    const game = window.game;
    if (!game) return false;

    if (typeof requestAnimationFrame !== 'function' || typeof performance?.now !== 'function')
      return true;

    // Rolling window of timestamps (ms) for FPS estimation.
    const times = [];
    let low28Since = null; // avg < 28 for >= 2s
    let low18Since = null; // avg < 18 for >= 0.7s

    function avgFpsOverWindow(now, windowMs) {
      const cutoff = now - windowMs;
      while (times.length && times[0] < cutoff) times.shift();
      if (times.length < 2) return 60;
      const span = times[times.length - 1] - times[0];
      if (span <= 0) return 60;
      return ((times.length - 1) * 1000) / span;
    }

    function tick() {
      const now = performance.now();
      times.push(now);

      const avg2s = avgFpsOverWindow(now, 2000);
      const avg700 = avgFpsOverWindow(now, 700);

      if (avg2s < 28) {
        if (low28Since === null) low28Since = now;
      } else {
        low28Since = null;
      }

      if (avg700 < 18) {
        if (low18Since === null) low18Since = now;
      } else {
        low18Since = null;
      }

      let shouldDisable = false;
      let critical = false;
      let avgFps = Math.round(avg2s);

      if (low28Since !== null && now - low28Since >= 2000) {
        shouldDisable = true;
        critical = false;
        avgFps = Math.round(avg2s);
      }

      if (low18Since !== null && now - low18Since >= 700) {
        shouldDisable = true;
        critical = true;
        avgFps = Math.round(avg700);
      }

      if (shouldDisable) {
        dispatchAutoDisable({ reason: 'fps', averageFps: avgFps, critical: critical });
        // Do not stop the monitor; it may be re-enabled manually and can disable again later.
        low28Since = null;
        low18Since = null;
      }

      requestAnimationFrame(tick);
    }

    requestAnimationFrame(tick);
    return true;
  }

  // Start after init; retry a little while game bootstraps.
  let attempts = 0;
  (function retry() {
    attempts++;
    if (startMonitor()) return;
    if (attempts > 60) return; // ~6s
    setTimeout(retry, 100);
  })();
})();
