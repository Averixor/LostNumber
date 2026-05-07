class SettingsManager {
  constructor(game) {
    this.game = game;
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
    }
  }

  updateSettingsUI() {
    // Обновляем элементы UI в соответствии с текущими настройками
    const animationSelect = document.getElementById('animationSelect');
    const soundSelect = document.getElementById('soundSelect');
    const themeSelect = document.getElementById('themeSelect');
    const languageSelect = document.getElementById('languageSelect');

    if (animationSelect) {
      animationSelect.value = this.game.animationEnabled ? 'on' : 'off';
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
      soundEnabled: this.game.soundEnabled !== false,
      theme: this.game.theme || 'dusk',
      lang: this.game.lang || 'ua',
    };

    this.game.storageManager.saveSettings(settings);
  }
}
