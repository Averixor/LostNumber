class MenuManager {
  constructor(game) {
    this.game = game;
    this._newGameConfirmEscapeHandler = null;
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
        this.showNewGameConfirm();
      });
    }

    this.setupNewGameConfirm();

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

  setupNewGameConfirm() {
    const cancelBtn = document.getElementById('newGameConfirmCancel');
    const okBtn = document.getElementById('newGameConfirmOk');
    const backdrop = document.getElementById('newGameConfirmBackdrop');

    if (cancelBtn && !cancelBtn._lnBound) {
      cancelBtn.addEventListener('click', () => this.cancelNewGameConfirm());
      cancelBtn._lnBound = true;
    }

    if (okBtn && !okBtn._lnBound) {
      okBtn.addEventListener('click', () => this.confirmNewGameStart());
      okBtn._lnBound = true;
    }

    if (backdrop && !backdrop._lnBound) {
      backdrop.addEventListener('click', () => this.cancelNewGameConfirm());
      backdrop._lnBound = true;
    }
  }

  isNewGameConfirmOpen() {
    const overlay = document.getElementById('newGameConfirmOverlay');
    return !!(overlay && !overlay.classList.contains('hidden'));
  }

  showNewGameConfirm() {
    const overlay = document.getElementById('newGameConfirmOverlay');
    if (!overlay) return;

    overlay.classList.remove('hidden');

    const backdrop = document.getElementById('newGameConfirmBackdrop');
    if (backdrop) {
      backdrop.setAttribute('aria-label', this.game.t('cancel'));
    }

    const cancelBtn = document.getElementById('newGameConfirmCancel');
    if (cancelBtn) {
      cancelBtn.focus();
    }

    this._bindNewGameConfirmEscape();
  }

  hideNewGameConfirm() {
    const overlay = document.getElementById('newGameConfirmOverlay');
    if (overlay) {
      overlay.classList.add('hidden');
    }
    this._unbindNewGameConfirmEscape();
  }

  cancelNewGameConfirm() {
    if (!this.isNewGameConfirmOpen()) return;
    this.game.audioManager.playTap();
    this.hideNewGameConfirm();
  }

  confirmNewGameStart() {
    if (!this.isNewGameConfirmOpen()) return;
    this.game.audioManager.playTap();
    this.hideNewGameConfirm();

    this.game.storageManager.clearSave();
    this.game.hasSave = false;
    this.game.updateContinueButton(false);
    this.game.startNewGame();
  }

  dismissNewGameConfirmFromBack() {
    if (!this.isNewGameConfirmOpen()) return false;
    this.cancelNewGameConfirm();
    return true;
  }

  _bindNewGameConfirmEscape() {
    if (this._newGameConfirmEscapeHandler) return;

    this._newGameConfirmEscapeHandler = (e) => {
      if (!this.isNewGameConfirmOpen()) return;
      if (e.key === 'Escape' || e.key === 'Esc') {
        e.preventDefault();
        this.cancelNewGameConfirm();
      }
    };

    document.addEventListener('keydown', this._newGameConfirmEscapeHandler);
  }

  _unbindNewGameConfirmEscape() {
    if (!this._newGameConfirmEscapeHandler) return;
    document.removeEventListener('keydown', this._newGameConfirmEscapeHandler);
    this._newGameConfirmEscapeHandler = null;
  }

  syncSettingsUI() {
    if (this.game.settingsManager) {
      this.game.settingsManager.updateSettingsUI();
    }
  }
}
