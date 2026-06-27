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

  _volumeToSelectValue(volume) {
    const pct = Math.round(lnNormalizeVolume(volume, 0.5) * 100);
    if (pct <= 25) return '25';
    if (pct <= 50) return '50';
    if (pct <= 75) return '75';
    return '100';
  }

  _applyAudioFromForm() {
    this.game.soundEnabled = document.getElementById('soundSelect')?.value === 'on';
    this.game.musicEnabled = document.getElementById('musicSelect')?.value === 'on';
    this.game.sfxVolume = Number(document.getElementById('sfxVolumeSelect')?.value || 50) / 100;
    this.game.musicVolume = Number(document.getElementById('musicVolumeSelect')?.value || 30) / 100;
    this.game.musicTrack = document.getElementById('musicTrackSelect')?.value || 'ambient';

    this.game.audioManager.applySettings({
      soundEnabled: this.game.soundEnabled,
      musicEnabled: this.game.musicEnabled,
      sfxVolume: this.game.sfxVolume,
      musicVolume: this.game.musicVolume,
      musicTrack: this.game.musicTrack,
    });
    this.game.audioManager.updateSoundStateUI();
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
          const lite = document.getElementById('liteVisualSelect')?.value;
          this.game.liteVisualMode =
            lite === 'on' || lite === 'off' || lite === 'auto' ? lite : 'auto';
        }
        {
          const visualSkinValue = document.getElementById('visualSkinSelect')?.value || 'auto';
          const themeValue =
            document.getElementById('themeSelect')?.value || this.game.theme || 'dusk';
          this.game.theme = themeValue === 'dawn' ? 'dawn' : 'dusk';
          if (typeof BackgroundRotator !== 'undefined') {
            BackgroundRotator.setPreferenceValue(visualSkinValue, this.game.theme);
            this.game.visualSkinPreference = BackgroundRotator.getPreferenceValue(this.game.theme);
          } else {
            this.game.visualSkinPreference = visualSkinValue;
          }
        }
        const newLang = document.getElementById('languageSelect')?.value || 'ua';

        if (this.game.animationEnabled) {
          document.body.classList.remove('no-animations');
        } else {
          document.body.classList.add('no-animations');
        }

        this._applyAudioFromForm();
        this.game.applyTheme();
        this.game.applyLanguage(newLang);
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
      this.game.soundEnabled = settings.soundEnabled !== false;
      this.game.musicEnabled = settings.musicEnabled !== false;
      this.game.sfxVolume = lnNormalizeVolume(settings.sfxVolume, 0.5);
      this.game.musicVolume = lnNormalizeVolume(settings.musicVolume, 0.3);
      this.game.musicTrack = settings.musicTrack || 'ambient';
      this.game.theme =
        settings.theme === 'dawn' ? 'dawn' : settings.theme || this.game.theme || 'dusk';
      this.game.lang = settings.lang || this.game.lang || 'ua';
      const lv = settings.liteVisualMode;
      this.game.liteVisualMode = lv === 'on' || lv === 'off' || lv === 'auto' ? lv : 'auto';
      this.game.visualSkinPreference =
        typeof BackgroundRotator !== 'undefined'
          ? BackgroundRotator.getPreferenceValue(this.game.theme)
          : settings.visualSkinPreference || settings.backgroundPreference || 'auto';

      this.updateSettingsUI();

      if (!this.game.animationEnabled) {
        document.body.classList.add('no-animations');
      } else {
        document.body.classList.remove('no-animations');
      }

      this.applyLiteVisualMode();
    }
  }

  updateSettingsUI() {
    const animationSelect = document.getElementById('animationSelect');
    const liteVisualSelect = document.getElementById('liteVisualSelect');
    const soundSelect = document.getElementById('soundSelect');
    const musicSelect = document.getElementById('musicSelect');
    const sfxVolumeSelect = document.getElementById('sfxVolumeSelect');
    const musicVolumeSelect = document.getElementById('musicVolumeSelect');
    const musicTrackSelect = document.getElementById('musicTrackSelect');
    const visualSkinSelect = document.getElementById('visualSkinSelect');
    const themeSelect = document.getElementById('themeSelect');
    const languageSelect = document.getElementById('languageSelect');

    if (animationSelect) {
      animationSelect.value = this.game.animationEnabled ? 'on' : 'off';
    }

    if (liteVisualSelect) {
      const m = this.game.liteVisualMode;
      liteVisualSelect.value = m === 'on' || m === 'off' || m === 'auto' ? m : 'auto';
    }

    if (soundSelect) {
      soundSelect.value = this.game.soundEnabled ? 'on' : 'off';
    }

    if (musicSelect) {
      musicSelect.value = this.game.musicEnabled ? 'on' : 'off';
    }

    if (sfxVolumeSelect) {
      sfxVolumeSelect.value = this._volumeToSelectValue(this.game.sfxVolume);
    }

    if (musicVolumeSelect) {
      musicVolumeSelect.value = this._volumeToSelectValue(this.game.musicVolume);
    }

    if (musicTrackSelect) {
      musicTrackSelect.value = this.game.musicTrack || 'ambient';
    }

    if (visualSkinSelect) {
      visualSkinSelect.value =
        typeof BackgroundRotator !== 'undefined'
          ? BackgroundRotator.getPreferenceValue(this.game.theme)
          : this.game.visualSkinPreference || this.game.backgroundPreference || 'auto';
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
      soundEnabled: this.game.soundEnabled !== false,
      musicEnabled: this.game.musicEnabled !== false,
      sfxVolume: this.game.sfxVolume,
      musicVolume: this.game.musicVolume,
      musicTrack: this.game.musicTrack || 'ambient',
      theme: this.game.theme || 'dusk',
      lang: this.game.lang || 'ua',
      visualSkinPreference:
        typeof BackgroundRotator !== 'undefined'
          ? BackgroundRotator.getPreferenceValue(this.game.theme)
          : this.game.visualSkinPreference || 'auto',
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
