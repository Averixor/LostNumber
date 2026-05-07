class PlatformDetector {
  static isAndroidApp() {
    return !!(
      window.Capacitor ||
      window.AndroidInterface ||
      (navigator.userAgent && navigator.userAgent.includes('Android') && navigator.userAgent.includes('WebView'))
    );
  }

  static isIOS() {
    return /iPad|iPhone|iPod/.test(navigator.userAgent) && !window.MSStream;
  }

  static isMobile() {
    return /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent);
  }

  static isStandalone() {
    return window.matchMedia('(display-mode: standalone)').matches || window.navigator.standalone === true;
  }
}
