class MenuManager {
  constructor(game) {
    this.game = game;
    this._newGameConfirmEscapeHandler = null;
    this._featureStubEscapeHandler = null;
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
        if (this.game.hasSave) {
          this.showNewGameConfirm();
          return;
        }
        this.game.audioManager.playTap();
        this.game.storageManager.clearSave();
        this.game.hasSave = false;
        this.game.updateContinueButton(false);
        this.game.startNewGame();
      });
    }

    this.setupNewGameConfirm();
    this.setupFeatureStub();
    this.setupAccountActions();
    this.setupDockNavigation();
    this.setupSecondaryMenu();

    this.refreshMainMenuUI();
  }

  setupAccountActions() {
    const loginBtn = document.getElementById('loginBtn');
    if (loginBtn && !loginBtn._lnBound) {
      loginBtn.addEventListener('click', () => {
        this.game.audioManager.playTap();
        this.showFeatureStub('feature_login_title', 'feature_login_text');
      });
      loginBtn._lnBound = true;
    }

    const exitAppBtn = document.getElementById('exitAppBtn');
    if (exitAppBtn && !exitAppBtn._lnBound) {
      exitAppBtn.addEventListener('click', () => {
        this.game.audioManager.playTap();
        if (typeof this.game.requestAppExit === 'function') {
          this.game.requestAppExit();
        }
      });
      exitAppBtn._lnBound = true;
    }
  }

  setupDockNavigation() {
    const bindDock = (id, handler) => {
      const btn = document.getElementById(id);
      if (!btn || btn._lnBound) return;
      btn.addEventListener('click', () => {
        this.game.audioManager.playTap();
        handler();
      });
      btn._lnBound = true;
    };

    bindDock('dockPremiumBtn', () => {
      this.showFeatureStub('feature_premium_title', 'feature_premium_text');
    });

    bindDock('dockTournamentsBtn', () => {
      this.showFeatureStub('feature_tournaments_title', 'feature_tournaments_text');
    });

    bindDock('dockAchievementsBtn', () => {
      this.game.showAchievementsScreen();
    });

    bindDock('dockDailyBtn', () => {
      this.game.dailyQuestManager.renderDailyQuests();
      this.game.screenManager.showScreen('dailyQuests');
    });

    bindDock('dockBonusesBtn', () => {
      this.showFeatureStub('feature_bonuses_title', 'feature_bonuses_text');
    });
  }

  setupSecondaryMenu() {
    const settingsBtn = document.getElementById('settingsBtn');
    if (settingsBtn && !settingsBtn._lnBound) {
      settingsBtn.addEventListener('click', () => {
        this.game.audioManager.playTap();
        this.syncSettingsUI();
        this.game.screenManager.showScreen('settings');
      });
      settingsBtn._lnBound = true;
    }

    const statsBtn = document.getElementById('statsBtn');
    if (statsBtn && !statsBtn._lnBound) {
      statsBtn.addEventListener('click', () => {
        this.game.audioManager.playTap();
        this.game.showStatsScreen();
      });
      statsBtn._lnBound = true;
    }

    const aboutBtn = document.getElementById('aboutBtn');
    if (aboutBtn && !aboutBtn._lnBound) {
      aboutBtn.addEventListener('click', () => {
        this.game.audioManager.playTap();
        this.game.screenManager.showScreen('about');
      });
      aboutBtn._lnBound = true;
    }
  }

  refreshMainMenuUI() {
    try {
      const hasSave = this.game.hasSave === true;
      const continueBtn = document.getElementById('continueBtn');
      const newGameBtn = document.getElementById('newGameBtn');
      const newGameLabel = document.getElementById('newGameBtnLabel');

      if (newGameLabel) {
        newGameLabel.textContent = this.game.t(hasSave ? 'btn_new_game' : 'btn_play');
      }

      if (continueBtn) {
        continueBtn.classList.toggle('main-menu__cta-secondary', !hasSave);
      }
      if (newGameBtn) {
        newGameBtn.classList.toggle('primary', !hasSave);
        newGameBtn.classList.toggle('secondary', hasSave);
      }

      this.applyMainMenuIcons();
    } catch (error) {
      ErrorHandler.warn('refreshMainMenuUI failed', { error });
    }
  }

  applyMainMenuIcons() {
    try {
      if (typeof LostNumberIcons === 'undefined') return;
      const menu = document.getElementById('mainMenuScreen');
      if (menu) {
        LostNumberIcons.applyAll(menu);
      }
      const stub = document.getElementById('featureStubOverlay');
      if (stub && !stub.classList.contains('hidden')) {
        LostNumberIcons.applyAll(stub);
      }
    } catch (_) {}
  }

  setupFeatureStub() {
    const closeBtn = document.getElementById('featureStubClose');
    const backdrop = document.getElementById('featureStubBackdrop');

    if (closeBtn && !closeBtn._lnBound) {
      closeBtn.addEventListener('click', () => this.hideFeatureStub());
      closeBtn._lnBound = true;
    }

    if (backdrop && !backdrop._lnBound) {
      backdrop.addEventListener('click', () => this.hideFeatureStub());
      backdrop._lnBound = true;
    }
  }

  isFeatureStubOpen() {
    const overlay = document.getElementById('featureStubOverlay');
    return !!(overlay && !overlay.classList.contains('hidden'));
  }

  showFeatureStub(titleKey, textKey) {
    const overlay = document.getElementById('featureStubOverlay');
    const title = document.getElementById('featureStubTitle');
    const text = document.getElementById('featureStubText');
    if (!overlay || !title || !text) {
      this.game.showMessage(this.game.t(textKey || titleKey));
      return;
    }

    title.textContent = this.game.t(titleKey);
    text.textContent = this.game.t(textKey);
    overlay.classList.remove('hidden');
    this.applyMainMenuIcons();

    const closeBtn = document.getElementById('featureStubClose');
    if (closeBtn) {
      closeBtn.focus();
    }

    this._bindFeatureStubEscape();
  }

  hideFeatureStub() {
    const overlay = document.getElementById('featureStubOverlay');
    if (overlay) {
      overlay.classList.add('hidden');
    }
    this._unbindFeatureStubEscape();
  }

  dismissFeatureStubFromBack() {
    if (!this.isFeatureStubOpen()) return false;
    this.game.audioManager.playTap();
    this.hideFeatureStub();
    return true;
  }

  _bindFeatureStubEscape() {
    if (this._featureStubEscapeHandler) return;

    this._featureStubEscapeHandler = (e) => {
      if (!this.isFeatureStubOpen()) return;
      if (e.key === 'Escape' || e.key === 'Esc') {
        e.preventDefault();
        this.hideFeatureStub();
      }
    };

    document.addEventListener('keydown', this._featureStubEscapeHandler);
  }

  _unbindFeatureStubEscape() {
    if (!this._featureStubEscapeHandler) return;
    document.removeEventListener('keydown', this._featureStubEscapeHandler);
    this._featureStubEscapeHandler = null;
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
