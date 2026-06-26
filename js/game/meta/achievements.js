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

    const achievement =
      typeof this.game.getAchievement === 'function'
        ? this.game.getAchievement('useAllBonuses')
        : this.game.achievements?.useAllBonuses || null;
    if (!achievement) return;

    if (!Array.isArray(achievement.typesUsed)) {
      achievement.typesUsed = [];
    }
    if (achievement.typesUsed.includes(type)) return;

    achievement.typesUsed.push(type);
    this.updateAchievementProgress('useAllBonuses', 1);
  }

  renderAchievementsScreen() {
    const grid = document.getElementById('achievementsGrid');
    if (!grid) return;

    grid.innerHTML = '';

    const achievementsList = [
      { key: 'firstGame', icon: 'path' },
      { key: 'level10', icon: 'level' },
      { key: 'level25', icon: 'high-score' },
      { key: 'xp1000', icon: 'reward-xp' },
      { key: 'xp5000', icon: 'achievements' },
      { key: 'chain5', icon: 'chain' },
      { key: 'chain10', icon: 'path' },
      { key: 'useAllBonuses', icon: 'bonus' },
      { key: 'spinWheel', icon: 'wheel' },
      { key: 'spinWheel10', icon: 'wheel' },
    ];

    for (const { key, icon } of achievementsList) {
      const achievement = this.game.getAchievement(key);
      if (!achievement) continue;
      const item = document.createElement('div');
      item.className = `achievement-item ${achievement.unlocked ? '' : 'locked'}`;
      item.innerHTML = `
        <div class="achievement-icon"></div>
        <div class="achievement-title">${this.game.t('achievement_' + key)}</div>
        <div class="achievement-desc">${this.game.t('achievement_desc_' + key)}</div>
        <div class="achievement-progress">
          <div class="achievement-progress-bar" style="width: ${(achievement.progress / achievement.max) * 100}%"></div>
        </div>
      `;
      const iconHost = item.querySelector('.achievement-icon');
      if (iconHost && typeof LostNumberIcons !== 'undefined') {
        LostNumberIcons.mount(iconHost, achievement.unlocked ? icon : 'lock');
      }
      grid.appendChild(item);
    }
  }
}
