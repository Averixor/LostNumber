class StorageManager {
  constructor() {
    this.SAVE_KEY = 'lostNumberSave';
    this.SETTINGS_KEY = 'lostNumberSettings';
    this.FIRST_RUN_KEY = 'lostNumberFirstRun';
    this.DAILY_QUESTS_KEY = 'dailyQuests';

    // Memory fallback (если localStorage запрещен/упал)
    this._memorySave = null;
    this._memorySettings = null;
    this._usingMemory = false;
  }

  saveGameState(state) {
    try {
      localStorage.setItem(this.SAVE_KEY, JSON.stringify(state));
      return true;
    } catch (e) {
      console.error('Save failed:', e);
      this._usingMemory = true;
      this._memorySave = state;
      return true;
    }
  }

  loadGameState() {
    try {
      const raw = localStorage.getItem(this.SAVE_KEY);
      if (!raw) return null;
      return JSON.parse(raw);
    } catch (e) {
      console.error('Load failed:', e);
      this._usingMemory = true;
      return this._memorySave;
    }
  }

  saveSettings(settings) {
    try {
      localStorage.setItem(this.SETTINGS_KEY, JSON.stringify(settings));
      return true;
    } catch (e) {
      console.error('Settings save failed:', e);
      this._usingMemory = true;
      this._memorySettings = settings;
      return true;
    }
  }

  loadSettings() {
    try {
      const raw = localStorage.getItem(this.SETTINGS_KEY);
      if (!raw) return null;
      return JSON.parse(raw);
    } catch (e) {
      console.error('Settings load failed:', e);
      this._usingMemory = true;
      return this._memorySettings;
    }
  }

  clearSave() {
    try {
      localStorage.removeItem(this.SAVE_KEY);
      return true;
    } catch (e) {
      console.error('Clear save failed:', e);
      return false;
    }
  }

  clearAll() {
    try {
      localStorage.removeItem(this.SAVE_KEY);
      localStorage.removeItem(this.SETTINGS_KEY);
      localStorage.removeItem(this.FIRST_RUN_KEY);
      localStorage.removeItem(this.DAILY_QUESTS_KEY);
      return true;
    } catch (e) {
      console.error('Clear all failed:', e);
      return false;
    }
  }

  saveDailyQuests(quests) {
    try {
      localStorage.setItem(this.DAILY_QUESTS_KEY, JSON.stringify(quests));
      return true;
    } catch (e) {
      console.error('Daily quests save failed:', e);
      return false;
    }
  }

  loadDailyQuests() {
    try {
      const raw = localStorage.getItem(this.DAILY_QUESTS_KEY);
      if (!raw) return null;
      return JSON.parse(raw);
    } catch (e) {
      console.error('Daily quests load failed:', e);
      return null;
    }
  }

  isFirstRun() {
    return !localStorage.getItem(this.FIRST_RUN_KEY);
  }

  markFirstRunComplete() {
    try {
      localStorage.setItem(this.FIRST_RUN_KEY, 'true');
      return true;
    } catch (e) {
      console.error('Mark first run failed:', e);
      return false;
    }
  }
}
