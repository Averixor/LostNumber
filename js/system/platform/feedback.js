class FeedbackService {
  static FEEDBACK_EMAIL = 'rsabergman@gmail.com';
  static CLICK_COUNT_KEY = 'ln_feedback_click_count';
  static CLICK_LAST_KEY = 'ln_feedback_click_last';
  static ANALYTICS_EVENT = 'feedback_button_click';

  static trackFeedbackClick() {
    try {
      const storage = window.localStorage;
      if (storage) {
        const count = Number(storage.getItem(FeedbackService.CLICK_COUNT_KEY) || '0') + 1;
        storage.setItem(FeedbackService.CLICK_COUNT_KEY, String(count));
        storage.setItem(FeedbackService.CLICK_LAST_KEY, new Date().toISOString());
      }
    } catch (_) {}

    try {
      window.dispatchEvent(
        new CustomEvent('ln:feedback-click', {
          detail: { event: FeedbackService.ANALYTICS_EVENT },
        }),
      );
    } catch (_) {}

    try {
      const analytics = window.firebase?.analytics;
      if (analytics && typeof analytics.logEvent === 'function') {
        analytics.logEvent(FeedbackService.ANALYTICS_EVENT);
      }
    } catch (_) {}
  }

  static getFeedbackClickStats() {
    try {
      const storage = window.localStorage;
      if (!storage) {
        return { count: 0, lastClick: null };
      }
      return {
        count: Number(storage.getItem(FeedbackService.CLICK_COUNT_KEY) || '0'),
        lastClick: storage.getItem(FeedbackService.CLICK_LAST_KEY),
      };
    } catch (_) {
      return { count: 0, lastClick: null };
    }
  }

  static async getAppVersion() {
    try {
      const App = window.Capacitor?.Plugins?.App;
      if (App && typeof App.getInfo === 'function') {
        const info = await App.getInfo();
        return String(info?.version || info?.build || '').trim();
      }
    } catch (_) {}

    return '';
  }

  static getDeviceInfo() {
    const ua = navigator.userAgent || '';
    const screenSize =
      typeof window.screen?.width === 'number' && typeof window.screen?.height === 'number'
        ? `${window.screen.width}x${window.screen.height}`
        : '';

    if (PlatformDetector.isAndroidApp()) {
      return { labelKey: 'feedback_device_android', ua, screenSize };
    }
    if (PlatformDetector.isIOS()) {
      return { labelKey: 'feedback_device_ios', ua, screenSize };
    }
    return { labelKey: 'feedback_device_web', ua, screenSize };
  }

  static buildBody(t, appVersion, deviceInfo) {
    const lines = [
      t('feedback_body_intro'),
      '',
      '-------------------------------------',
      `${t(deviceInfo.labelKey)}: ${deviceInfo.ua}`,
    ];

    if (deviceInfo.screenSize) {
      lines.push(`${t('feedback_screen')}: ${deviceInfo.screenSize}`);
    }
    if (appVersion) {
      lines.push(`${t('feedback_app_version')}: ${appVersion}`);
    }

    return lines.join('\n');
  }

  static _openMailtoUrl(url) {
    const link = document.createElement('a');
    link.href = url;
    link.rel = 'noopener noreferrer';
    link.style.display = 'none';
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  }

  static _notifyNoEmailClient(t) {
    const message = t('feedback_no_email_client');
    if (typeof window.alert === 'function') {
      window.alert(message);
      return;
    }
    console.warn(message);
  }

  static async openFeedbackEmail(t = (key) => key) {
    FeedbackService.trackFeedbackClick();

    const subject = t('feedback_subject');
    const appVersion = await FeedbackService.getAppVersion();
    const deviceInfo = FeedbackService.getDeviceInfo();
    const body = FeedbackService.buildBody(t, appVersion, deviceInfo);

    const Feedback = window.Capacitor?.Plugins?.Feedback;
    if (Feedback && typeof Feedback.openEmail === 'function') {
      try {
        const result = await Feedback.openEmail({
          email: FeedbackService.FEEDBACK_EMAIL,
          subject,
          body,
          chooserTitle: t('feedback_chooser_title'),
          errorMessage: t('feedback_no_email_client'),
        });
        if (result && result.opened === false) {
          FeedbackService._notifyNoEmailClient(t);
        }
        return;
      } catch (_) {
        FeedbackService._notifyNoEmailClient(t);
        return;
      }
    }

    const url =
      `mailto:${FeedbackService.FEEDBACK_EMAIL}` +
      `?subject=${encodeURIComponent(subject)}` +
      `&body=${encodeURIComponent(body)}`;

    try {
      FeedbackService._openMailtoUrl(url);
    } catch (_) {
      FeedbackService._notifyNoEmailClient(t);
    }
  }
}
