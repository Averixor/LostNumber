class AchievementManager {
  constructor(game) {
    this.game = game;
  }

  updateAchievementProgress(key, value = 1) {
    const achievement =
      typeof this.game.getAchievement === 'function'
        ? this.game.getAchievement(key)
        : this.game.achievements?.[key] || null;
    if (!achievement) return;

    achievement.progress = Math.min(achievement.max, achievement.progress + value);

    if (achievement.progress >= achievement.max && !achievement.unlocked) {
      achievement.unlocked = true;
      this.game.showMessage(
        this.game.formatTemplate('achievement_unlocked', {
          title: this.game.t('achievement_' + key),
        }),
      );
    }
  }

  trackBonusTypeUsed(type) {
    if (!type) return;
    if (!this._bonusTypesUsed) {
      this._bonusTypesUsed = new Set();
    }
    if (this._bonusTypesUsed.has(type)) return;
    this._bonusTypesUsed.add(type);
    this.updateAchievementProgress('useAllBonuses', 1);
  }

  renderAchievementsScreen() {
    const grid = document.getElementById('achievementsGrid');
    if (!grid) return;

    grid.innerHTML = '';

    const achievementsList = [
      { key: 'firstGame', icon: '👣' },
      { key: 'level10', icon: '📈' },
      { key: 'level25', icon: '🎯' },
      { key: 'xp1000', icon: '⭐' },
      { key: 'xp5000', icon: '🏆' },
      { key: 'chain5', icon: '🔗' },
      { key: 'chain10', icon: '⛓️' },
      { key: 'useAllBonuses', icon: '✨' },
      { key: 'spinWheel', icon: '🌀' },
      { key: 'spinWheel10', icon: '🎰' },
    ];

    for (const { key, icon } of achievementsList) {
      const achievement = this.game.getAchievement(key);
      if (!achievement) continue;
      const item = document.createElement('div');
      item.className = `achievement-item ${achievement.unlocked ? '' : 'locked'}`;
      item.innerHTML = `
        <div class="achievement-icon">${achievement.unlocked ? icon : '🔒'}</div>
        <div class="achievement-title">${this.game.t('achievement_' + key)}</div>
        <div class="achievement-desc">${this.game.t('achievement_desc_' + key)}</div>
        <div class="achievement-progress">
          <div class="achievement-progress-bar" style="width: ${(achievement.progress / achievement.max) * 100}%"></div>
        </div>
      `;
      grid.appendChild(item);
    }
  }
}
