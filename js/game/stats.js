class StatsManager {
  constructor(game) {
    this.game = game;
  }

  renderStats() {
    const grid = document.getElementById('statsGrid');
    if (!grid) return;

    grid.innerHTML = '';

    const items = [
      ['stat_games_played', this.game.formatNumber(this.game.stats.gamesPlayed)],
      ['stat_levels_completed', this.game.formatNumber(this.game.stats.levelsCompleted)],
      ['stat_highest_level', this.game.formatNumber(this.game.stats.highestLevel)],
      ['stat_total_xp', this.game.formatNumber(this.game.stats.totalXP)],
      ['stat_longest_chain', this.game.formatNumber(this.game.stats.longestChain)],
      ['stat_bonuses_used', this.game.formatNumber(this.game.stats.bonusesUsed)],
      ['stat_wheel_spins', this.game.formatNumber(this.game.stats.wheelSpins)],
    ];

    items.forEach(([labelKey, value]) => {
      const div = document.createElement('div');
      div.className = 'stat-item';
      div.innerHTML = `
        <div class="stat-value">${value}</div>
        <div class="stat-label">${this.game.t(labelKey)}</div>
      `;
      grid.appendChild(div);
    });
  }
}
