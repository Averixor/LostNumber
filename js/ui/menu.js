class MenuManager {
  constructor(game) {
    this.game = game;
  }

  setupMainMenu() {
    const continueBtn = document.getElementById('continueBtn');
    const newGameBtn = document.getElementById('newGameBtn');

    if (continueBtn) {
      continueBtn.addEventListener('click', () => {
        this.game.audioManager.playTap();
        this.game.audioManager.init();
        this.game.audioManager.playMusic();
        this.game.resumeGame();
      });
    }

    if (newGameBtn) {
      newGameBtn.addEventListener('click', () => {
        this.game.audioManager.playTap();
        this.game.audioManager.init();
        this.game.audioManager.playMusic();

        if (this.game.hasSave) {
          const ok = confirm(this.game.t('confirm_new_game'));
          if (!ok) return;
        }

        this.game.storageManager.clearSave();
        this.game.hasSave = false;
        this.game.startNewGame();
      });
    }

    const settingsBtn = document.getElementById('settingsBtn');
    if (settingsBtn) {
      settingsBtn.addEventListener('click', () => {
        this.game.audioManager.playTap();
        this.syncSettingsUI();
        this.game.screenManager.showScreen('settings');
      });
    }

    const achievementsBtn = document.getElementById('achievementsBtn');
    if (achievementsBtn) {
      achievementsBtn.addEventListener('click', () => {
        this.game.audioManager.playTap();
        this.game.showAchievementsScreen();
      });
    }

    const statsBtn = document.getElementById('statsBtn');
    if (statsBtn) {
      statsBtn.addEventListener('click', () => {
        this.game.audioManager.playTap();
        this.game.showStatsScreen();
      });
    }

    const dailyQuestsBtn = document.getElementById('dailyQuestsBtn');
    if (dailyQuestsBtn) {
      dailyQuestsBtn.addEventListener('click', () => {
        this.game.audioManager.playTap();
        this.game.dailyQuestManager.renderDailyQuests();
        this.game.screenManager.showScreen('dailyQuests');
      });
    }
  }

  syncSettingsUI() {
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
      themeSelect.value = this.game.theme || 'dawn';
    }
    if (languageSelect) {
      languageSelect.value = this.game.lang || 'ua';
    }
  }
}
