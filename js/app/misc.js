// Miscellaneous LostNumberGame prototype methods.

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
    if (this.statsManager) {
      this.statsManager.renderStats();
    }
    this.showScreen('stats');
  } catch (error) {
    ErrorHandler.handle(error, { type: 'ui_navigation', screen: 'stats' });
  }
};
