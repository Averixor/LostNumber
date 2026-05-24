LostNumberGame.prototype.showAchievementsScreen = function () {
  try {
    if (this.achievementManager) {
      this.achievementManager.renderAchievementsScreen();
    }
    this.showScreen('achievements');
  } catch (error) {
    ErrorHandler.handle(error, { type: 'ui_navigation', screen: 'achievements' });
  }
};

LostNumberGame.prototype.showStatsScreen = function () {
  try {
    const open = () => {
      try {
        if (this.statsManager) {
          this.statsManager.renderStats();
        }
      } catch (e) {
        ErrorHandler.warn('renderStats failed', e);
      }
      this.showScreen('stats');
    };

    if (this.statsManager) {
      open();
      return;
    }

    if (typeof window.LN_loadScriptOnce === 'function') {
      window
        .LN_loadScriptOnce('js/game/stats.js')
        .then(() => {
          try {
            if (!this.statsManager && typeof StatsManager !== 'undefined') {
              this.statsManager = new StatsManager(this);
            }
          } catch (e) {
            ErrorHandler.warn('StatsManager init failed', e);
          }
          open();
        })
        .catch((error) => {
          ErrorHandler.handle(error, { type: 'ui_navigation', screen: 'stats' });
          this.showScreen('stats');
        });
      return;
    }

    open();
  } catch (error) {
    ErrorHandler.handle(error, { type: 'ui_navigation', screen: 'stats' });
  }
};
