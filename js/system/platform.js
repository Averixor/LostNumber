class PlatformDetector {
  static shouldPreferLiteVisual() {
    try {
      const ua = navigator.userAgent || '';
      const isXiaomiBrowser = /MiuiBrowser|MiBrowser|XiaoMi/i.test(ua);
      const isMobile = /Android|iPhone|iPad|iPod/i.test(ua);
      const lowMemory = typeof navigator.deviceMemory === 'number' && navigator.deviceMemory <= 4;
      const lowCores =
        typeof navigator.hardwareConcurrency === 'number' && navigator.hardwareConcurrency <= 4;
      const mm = typeof window.matchMedia === 'function' ? window.matchMedia.bind(window) : null;
      const reduceMotion = mm ? mm('(prefers-reduced-motion: reduce)').matches : false;
      const coarseTouch =
        mm && isMobile ? mm('(pointer: coarse)').matches || mm('(hover: none)').matches : false;

      return (
        isXiaomiBrowser || reduceMotion || (isMobile && (lowMemory || lowCores || coarseTouch))
      );
    } catch (_) {
      return false;
    }
  }

  static isAndroidApp() {
    return !!(
      window.Capacitor ||
      window.AndroidInterface ||
      (navigator.userAgent &&
        navigator.userAgent.includes('Android') &&
        navigator.userAgent.includes('WebView'))
    );
  }

  static isIOS() {
    return /iPad|iPhone|iPod/.test(navigator.userAgent) && !window.MSStream;
  }

  static isMobile() {
    return /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(
      navigator.userAgent,
    );
  }

  static isStandalone() {
    return (
      window.matchMedia('(display-mode: standalone)').matches ||
      window.navigator.standalone === true
    );
  }
}
