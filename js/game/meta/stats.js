class StatsManager {
  constructor(game) {
    this.game = game;
  }

  renderStats() {
    const grid = document.getElementById('statsGrid');
    if (!grid) return;

    grid.innerHTML = '';
    const getStat =
      typeof this.game.getStat === 'function'
        ? (key) => this.game.getStat(key)
        : (key) => this.game?.stats?.[key] || 0;

    const items = [
      ['stat_games_played', this.game.formatNumber(getStat('gamesPlayed'))],
      ['stat_levels_completed', this.game.formatNumber(getStat('levelsCompleted'))],
      ['stat_highest_level', this.game.formatNumber(getStat('highestLevel'))],
      ['stat_total_xp', this.game.formatNumber(getStat('totalXP'))],
      ['stat_longest_chain', this.game.formatNumber(getStat('longestChain'))],
      ['stat_bonuses_used', this.game.formatNumber(getStat('bonusesUsed'))],
      ['stat_wheel_spins', this.game.formatNumber(getStat('wheelSpins'))],
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
