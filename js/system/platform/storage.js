class StorageManager {
  constructor() {
    this.SAVE_KEY = 'lostNumberSave';
    this.SETTINGS_KEY = 'lostNumberSettings';
    this.FIRST_RUN_KEY = 'lostNumberFirstRun';
    this.DAILY_QUESTS_KEY = 'dailyQuests';

    this._memorySave = null;
    this._memorySettings = null;
    this._memoryDailyQuests = null;
    this._usingMemory = false;
  }

  isStorageDegraded() {
    return this._usingMemory === true;
  }

  saveGameState(state) {
    try {
      localStorage.setItem(this.SAVE_KEY, JSON.stringify(state));
      this._memorySave = state;
      return true;
    } catch (e) {
      console.error('Save failed:', e);
      this._usingMemory = true;
      this._memorySave = state;
      return true;
    }
  }

  loadGameState() {
    let parsed = null;
    try {
      const raw = localStorage.getItem(this.SAVE_KEY);
      if (raw) {
        parsed = JSON.parse(raw);
      }
    } catch (e) {
      console.error('Load failed:', e);
      this._usingMemory = true;
    }

    if (parsed) {
      return parsed;
    }
    if (this._memorySave) {
      this._usingMemory = true;
      return this._memorySave;
    }
    return null;
  }

  saveSettings(settings) {
    try {
      localStorage.setItem(this.SETTINGS_KEY, JSON.stringify(settings));
      this._memorySettings = settings;
      return true;
    } catch (e) {
      console.error('Settings save failed:', e);
      this._usingMemory = true;
      this._memorySettings = settings;
      return true;
    }
  }

  loadSettings() {
    let parsed = null;
    try {
      const raw = localStorage.getItem(this.SETTINGS_KEY);
      if (raw) {
        parsed = JSON.parse(raw);
      }
    } catch (e) {
      console.error('Settings load failed:', e);
      this._usingMemory = true;
    }

    if (parsed) {
      return parsed;
    }
    if (this._memorySettings) {
      this._usingMemory = true;
      return this._memorySettings;
    }
    return null;
  }

  clearSave() {
    try {
      localStorage.removeItem(this.SAVE_KEY);
      this._memorySave = null;
      return true;
    } catch (e) {
      console.error('Clear save failed:', e);
      this._memorySave = null;
      return false;
    }
  }

  saveDailyQuests(quests) {
    try {
      localStorage.setItem(this.DAILY_QUESTS_KEY, JSON.stringify(quests));
      this._memoryDailyQuests = quests;
      return true;
    } catch (e) {
      console.error('Daily quests save failed:', e);
      this._usingMemory = true;
      this._memoryDailyQuests = quests;
      return true;
    }
  }

  loadDailyQuests() {
    let parsed = null;
    try {
      const raw = localStorage.getItem(this.DAILY_QUESTS_KEY);
      if (raw) {
        parsed = JSON.parse(raw);
      }
    } catch (e) {
      console.error('Daily quests load failed:', e);
      this._usingMemory = true;
    }

    if (parsed) {
      return parsed;
    }
    if (this._memoryDailyQuests) {
      this._usingMemory = true;
      return this._memoryDailyQuests;
    }
    return null;
  }

  isFirstRun() {
    try {
      return !localStorage.getItem(this.FIRST_RUN_KEY);
    } catch (e) {
      this._usingMemory = true;
      return true;
    }
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
