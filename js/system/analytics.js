// analytics.js — локальная аналитика (без сервера)
class AnalyticsManager {
  constructor(game) {
    this.game = game;
    this.key = 'lostnumber_analytics_v1';
    this.max = 1000;
    this.daysToKeep = 30;
  }

  _load() {
    try {
      const raw = localStorage.getItem(this.key);
      return raw ? JSON.parse(raw) : [];
    } catch (_) {
      return [];
    }
  }

  _save(rows) {
    try {
      localStorage.setItem(this.key, JSON.stringify(rows.slice(-this.max)));
    } catch (_) {}
  }

  log(event, data = {}) {
    const rows = this._load();
    rows.push({
      t: Date.now(),
      event: String(event || 'event'),
      data,
    });
    // чистим старье
    const cutoff = Date.now() - this.daysToKeep * 24 * 3600 * 1000;
    const filtered = rows.filter((r) => r.t >= cutoff);
    this._save(filtered);
  }

  stats() {
    const rows = this._load();
    return {
      count: rows.length,
      last: rows[rows.length - 1] || null,
    };
  }
}
