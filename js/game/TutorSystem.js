// TutorSystem.js — мягкие подсказки новичкам (1 раз)
class TutorSystem {
  constructor(game) {
    this.game = game;
    this.key = 'lostnumber_tutor_seen_v1';
    this.seen = this._load();
    this.lastHintAt = 0;
  }

  _load() {
    try {
      return JSON.parse(localStorage.getItem(this.key) || '{}');
    } catch (_) {
      return {};
    }
  }

  _save() {
    try {
      localStorage.setItem(this.key, JSON.stringify(this.seen));
    } catch (_) {}
  }

  maybeHint(key, text) {
    const g = this.game;
    if (this.seen[key]) return;
    const now = Date.now();
    if (now - this.lastHintAt < 60_000) return; // не чаще 1/мин
    this.lastHintAt = now;
    g.showMessage(text);
    this.seen[key] = true;
    this._save();
  }

  onLevelStart(level) {
    if (level <= 2) this.maybeHint('lvl1', this.game.t('hint_lvl1') || 'Соединяйте одинаковые числа.');
    if (level === 4) this.maybeHint('lvl5', this.game.t('hint_lvl5') || 'Сумма цепочки должна быть степенью двойки.');
    if (level === 7) this.maybeHint('lvl8', this.game.t('hint_lvl8') || 'Если не видите хода — используйте бонусы.');
  }
}
