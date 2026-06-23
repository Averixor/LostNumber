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
        this.game.resumeGame();
      });
    }

    if (newGameBtn) {
      newGameBtn.addEventListener('click', () => {
        this.game.audioManager.playTap();

        if (this.game.hasSave) {
          const ok = confirm(this.game.t('confirm_new_game'));
          if (!ok) return;
        }

        this.game.storageManager.clearSave();
        this.game.hasSave = false;
        this.game.updateContinueButton(false);
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

    const aboutBtn = document.getElementById('aboutBtn');
    if (aboutBtn) {
      aboutBtn.addEventListener('click', () => {
        this.game.audioManager.playTap();
        this.game.screenManager.showScreen('about');
      });
    }
  }

  syncSettingsUI() {
    if (this.game.settingsManager) {
      this.game.settingsManager.updateSettingsUI();
    }
  }
}
