class SettingsManager {
  constructor(game) {
    this.game = game;
  }

  applyFloatingNumbers() {
    try {
      if (this.game.floatingNumbersEnabled === false) {
        document.documentElement.classList.add('floating-numbers-disabled');
        const container = document.getElementById('floatingHearts');
        if (container) container.innerHTML = '';
      } else {
        document.documentElement.classList.remove('floating-numbers-disabled');
        if (this.game.screenManager && typeof this.game.screenManager.createFloatingNumbers === 'function') {
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

        // Получаем значения из UI
        this.game.animationEnabled = document.getElementById('animationSelect').value === 'on';
        {
          const on = document.getElementById('bgEffectsSelect')?.value !== 'off';
          this.game.floatingNumbersEnabled = on;
          this.game.floatingNumbersDisabledBy = on ? null : 'user';
        }
        this.game.soundEnabled = document.getElementById('soundSelect').value === 'on';
        this.game.theme = document.getElementById('themeSelect')?.value || 'dusk';
        const newLang = document.getElementById('languageSelect').value || 'ua';

        // Применяем настройки анимаций
        if (this.game.animationEnabled) {
          document.body.classList.remove('no-animations');
        } else {
          document.body.classList.add('no-animations');
        }

        // Применяем настройки звука
        this.game.audioManager.setSoundEnabled(this.game.soundEnabled);
        this.game.audioManager.updateSoundStateUI();

        // Применяем язык
        this.game.applyLanguage(newLang);

        // Применяем настройки плавающих фоновых чисел
        this.applyFloatingNumbers();

        // Сохраняем настройки
        this.saveSettings();

        // Переходим в главное меню
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
      // Загружаем настройки из хранилища
      this.game.animationEnabled = settings.animationEnabled !== false;
      // Backward compat: previously saved as backgroundEffectsEnabled (boolean).
      const legacyBg = settings.backgroundEffectsEnabled;
      this.game.floatingNumbersEnabled =
        typeof settings.floatingNumbersEnabled === 'boolean' ? settings.floatingNumbersEnabled : legacyBg !== false;
      this.game.floatingNumbersDisabledBy =
        settings.floatingNumbersDisabledBy === 'fps' || settings.floatingNumbersDisabledBy === 'user'
          ? settings.floatingNumbersDisabledBy
          : this.game.floatingNumbersEnabled
            ? null
            : 'user';
      this.game.soundEnabled = settings.soundEnabled !== false;
      this.game.theme = settings.theme || this.game.theme || 'dusk';
      this.game.lang = settings.lang || this.game.lang || 'ua';

      // Обновляем UI настроек
      this.updateSettingsUI();

      // Применяем настройки анимаций
      if (!this.game.animationEnabled) {
        document.body.classList.add('no-animations');
      } else {
        document.body.classList.remove('no-animations');
      }

      this.applyFloatingNumbers();
    }
  }

  updateSettingsUI() {
    // Обновляем элементы UI в соответствии с текущими настройками
    const animationSelect = document.getElementById('animationSelect');
    const bgEffectsSelect = document.getElementById('bgEffectsSelect');
    const soundSelect = document.getElementById('soundSelect');
    const themeSelect = document.getElementById('themeSelect');
    const languageSelect = document.getElementById('languageSelect');

    if (animationSelect) {
      animationSelect.value = this.game.animationEnabled ? 'on' : 'off';
    }

    if (bgEffectsSelect) {
      bgEffectsSelect.value = this.game.floatingNumbersEnabled === false ? 'off' : 'on';
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
    };

    this.game.storageManager.saveSettings(settings);
  }
}
