class SettingsManager {
  constructor(game) {
    this.game = game;
  }

  applyLiteVisualMode() {
    try {
      const raw = this.game.liteVisualMode;
      const mode = raw === 'on' || raw === 'off' || raw === 'auto' ? raw : 'auto';

      let lite = false;
      if (mode === 'on') lite = true;
      else if (mode === 'off') lite = false;
      else
        lite =
          typeof PlatformDetector !== 'undefined' && PlatformDetector.shouldPreferLiteVisual?.();

      document.documentElement.classList.toggle('low-performance', lite);
    } catch (error) {
      ErrorHandler.warn('applyLiteVisualMode failed', { error });
    }
  }

  applyFloatingNumbers() {
    try {
      if (this.game.floatingNumbersEnabled === false) {
        document.documentElement.classList.add('floating-numbers-disabled');
        const container = document.getElementById('floatingHearts');
        if (container) container.innerHTML = '';
      } else {
        document.documentElement.classList.remove('floating-numbers-disabled');
        if (
          this.game.screenManager &&
          typeof this.game.screenManager.createFloatingNumbers === 'function'
        ) {
          this.game.screenManager.createFloatingNumbers();
        }
      }
    } catch (error) {
      ErrorHandler.warn('applyFloatingNumbers failed', { error });
    }
  }

  setupSettings() {
    const backFromSettingsBtn = document.getElementById('backFromSettingsBtn');
    if (backFromSettingsBtn) {
      backFromSettingsBtn.addEventListener('click', () => {
        this.game.audioManager.playTap();
        this.game.screenManager.showScreen('mainMenu');
      });
    }

    const saveSettingsBtn = document.getElementById('saveSettingsBtn');
    if (saveSettingsBtn) {
      saveSettingsBtn.addEventListener('click', () => {
        this.game.audioManager.playTap();

        this.game.animationEnabled = document.getElementById('animationSelect')?.value === 'on';
        {
          const on = document.getElementById('bgEffectsSelect')?.value !== 'off';
          this.game.floatingNumbersEnabled = on;
          this.game.floatingNumbersDisabledBy = on ? null : 'user';
        }
        {
          const lite = document.getElementById('liteVisualSelect')?.value;
          this.game.liteVisualMode =
            lite === 'on' || lite === 'off' || lite === 'auto' ? lite : 'auto';
        }
        this.game.soundEnabled = document.getElementById('soundSelect')?.value === 'on';
        this.game.theme = document.getElementById('themeSelect')?.value || 'dusk';
        const newLang = document.getElementById('languageSelect')?.value || 'ua';

        if (this.game.animationEnabled) {
          document.body.classList.remove('no-animations');
        } else {
          document.body.classList.add('no-animations');
        }

        this.game.audioManager.setSoundEnabled(this.game.soundEnabled);
        this.game.audioManager.updateSoundStateUI();

        this.game.applyLanguage(newLang);

        this.applyFloatingNumbers();

        this.applyLiteVisualMode();

        this.saveSettings();

        this.game.screenManager.showScreen('mainMenu');
      });
    }

    const backFromDailyQuestsBtn = document.getElementById('backFromDailyQuestsBtn');
    if (backFromDailyQuestsBtn) {
      backFromDailyQuestsBtn.addEventListener('click', () => {
        this.game.audioManager.playTap();
        this.game.screenManager.showScreen('mainMenu');
      });
    }

    const backFromAchievementsBtn = document.getElementById('backFromAchievementsBtn');
    if (backFromAchievementsBtn) {
      backFromAchievementsBtn.addEventListener('click', () => {
        this.game.audioManager.playTap();
        this.game.screenManager.showScreen('mainMenu');
      });
    }

    const backFromStatsBtn = document.getElementById('backFromStatsBtn');
    if (backFromStatsBtn) {
      backFromStatsBtn.addEventListener('click', () => {
        this.game.audioManager.playTap();
        this.game.screenManager.showScreen('mainMenu');
      });
    }

    const backFromAboutBtn = document.getElementById('backFromAboutBtn');
    if (backFromAboutBtn) {
      backFromAboutBtn.addEventListener('click', () => {
        this.game.audioManager.playTap();
        this.game.screenManager.showScreen('mainMenu');
      });
    }
  }

  loadSettings() {
    const settings = this.game.storageManager.loadSettings();

    if (settings) {
      this.game.animationEnabled = settings.animationEnabled !== false;
      const legacyBg = settings.backgroundEffectsEnabled;
      this.game.floatingNumbersEnabled =
        typeof settings.floatingNumbersEnabled === 'boolean'
          ? settings.floatingNumbersEnabled
          : legacyBg !== false;
      this.game.floatingNumbersDisabledBy =
        settings.floatingNumbersDisabledBy === 'fps' ||
        settings.floatingNumbersDisabledBy === 'user'
          ? settings.floatingNumbersDisabledBy
          : this.game.floatingNumbersEnabled
            ? null
            : 'user';
      this.game.soundEnabled = settings.soundEnabled !== false;
      this.game.theme = settings.theme || this.game.theme || 'dusk';
      this.game.lang = settings.lang || this.game.lang || 'ua';
      const lv = settings.liteVisualMode;
      this.game.liteVisualMode = lv === 'on' || lv === 'off' || lv === 'auto' ? lv : 'auto';

      this.updateSettingsUI();

      if (!this.game.animationEnabled) {
        document.body.classList.add('no-animations');
      } else {
        document.body.classList.remove('no-animations');
      }

      this.applyFloatingNumbers();
      this.applyLiteVisualMode();
    }
  }

  updateSettingsUI() {
    const animationSelect = document.getElementById('animationSelect');
    const bgEffectsSelect = document.getElementById('bgEffectsSelect');
    const liteVisualSelect = document.getElementById('liteVisualSelect');
    const soundSelect = document.getElementById('soundSelect');
    const themeSelect = document.getElementById('themeSelect');
    const languageSelect = document.getElementById('languageSelect');

    if (animationSelect) {
      animationSelect.value = this.game.animationEnabled ? 'on' : 'off';
    }

    if (bgEffectsSelect) {
      bgEffectsSelect.value = this.game.floatingNumbersEnabled === false ? 'off' : 'on';
    }

    if (liteVisualSelect) {
      const m = this.game.liteVisualMode;
      liteVisualSelect.value = m === 'on' || m === 'off' || m === 'auto' ? m : 'auto';
    }

    if (soundSelect) {
      soundSelect.value = this.game.soundEnabled ? 'on' : 'off';
    }

    if (themeSelect) {
      themeSelect.value = this.game.theme || 'dusk';
    }

    if (languageSelect) {
      languageSelect.value = this.game.lang || 'ua';
    }
  }

  saveSettings() {
    const settings = {
      animationEnabled: this.game.animationEnabled !== false,
      floatingNumbersEnabled: this.game.floatingNumbersEnabled !== false,
      floatingNumbersDisabledBy: this.game.floatingNumbersDisabledBy || null,
      soundEnabled: this.game.soundEnabled !== false,
      theme: this.game.theme || 'dusk',
      lang: this.game.lang || 'ua',
      liteVisualMode:
        this.game.liteVisualMode === 'on' ||
        this.game.liteVisualMode === 'off' ||
        this.game.liteVisualMode === 'auto'
          ? this.game.liteVisualMode
          : 'auto',
    };

    this.game.storageManager.saveSettings(settings);
  }
}
