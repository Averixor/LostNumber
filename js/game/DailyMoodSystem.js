// DailyMoodSystem.js — модификатор дня (локально)
class DailyMoodSystem {
  constructor(game) {
    this.game = game;
    this.mood = null;
  }

  computeMood() {
    const g = this.game;
    const todayKey = g.getTodayKey ? g.getTodayKey() : new Date().toISOString().slice(0, 10);
    const seed = typeof SeededRandom !== 'undefined' ? SeededRandom.hashToSeed(`mood|${todayKey}`) : 0;
    const moods = [
      { id: 'double', label: 'День удвоения', xpMult: 1.5 },
      { id: 'minimal', label: 'День минимализма', xpMult: 1.0 },
      { id: 'balance', label: 'День баланса', xpMult: 1.1 },
      { id: 'speed', label: 'День скорости', xpMult: 1.0 },
      { id: 'risk', label: 'День риска', xpMult: 1.0 },
    ];
    this.mood = moods[seed % moods.length];
    return this.mood;
  }

  getXPMultiplier() {
    if (!this.mood) this.computeMood();
    return this.mood?.xpMult || 1.0;
  }
}
