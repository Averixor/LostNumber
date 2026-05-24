class DailyQuestManager {
  constructor(game) {
    this.game = game;
    try {
      this.storage = game.storageManager || new StorageManager();
    } catch (error) {
      this.storage = null;
      if (typeof ErrorHandler !== 'undefined') {
        ErrorHandler.handle(error, { type: 'daily_storage_init' });
      }
    }
    this.quests = null;
  }

  loadDailyQuests() {
    const saved =
      this.storage && typeof this.storage.loadDailyQuests === 'function'
        ? this.storage.loadDailyQuests()
        : null;
    const today = this.game.getTodayKey();

    if (saved && saved.date === today) {
      this.quests = saved;
      this.game.dailyQuests = saved;
      return saved;
    }

    this.quests = {
      date: today,
      completed: {},
      list: [
        {
          id: 'completeLevel',
          textKey: 'daily_complete_level',
          rewardKey: 'reward_xp_20',
        },
        {
          id: 'chain5',
          textKey: 'daily_chain_5',
          rewardKey: 'reward_bomb_1',
        },
        {
          id: 'xp100',
          textKey: 'daily_xp_100',
          rewardKey: 'reward_xp_30',
        },
        {
          id: 'useBonus',
          textKey: 'daily_use_bonus',
          rewardKey: 'reward_shuffle_1',
        },
        {
          id: 'spinWheel',
          textKey: 'daily_spin_wheel',
          rewardKey: 'reward_xp_15',
        },
      ],
    };

    this.game.dailyQuests = this.quests;
    if (this.storage && typeof this.storage.saveDailyQuests === 'function') {
      this.storage.saveDailyQuests(this.quests);
    }
    return this.quests;
  }

  renderDailyQuests() {
    const container = document.getElementById('dailyQuestsList');
    if (!container) return;

    if (!this.quests) {
      this.loadDailyQuests();
    }

    if (!this.quests || !Array.isArray(this.quests.list)) return;

    container.innerHTML = '';

    this.quests.list.forEach((q) => {
      const done = this.quests.completed[q.id];

      const div = document.createElement('div');
      div.className = 'setting-item';
      div.innerHTML = `
        <strong>${done ? '✅' : '⬜'} ${this.game.t(q.textKey)}</strong>
        <div style="font-size:0.8rem;opacity:0.8;">${this.game.t(q.rewardKey)}</div>
      `;
      container.appendChild(div);
    });
  }

  updateDailyIndicator() {
    const el = document.getElementById('dailyIndicator');
    if (!el) return;

    if (!this.quests) {
      this.loadDailyQuests();
    }

    const total = this.quests.list.length;
    const done = Object.keys(this.quests.completed).length;

    if (done >= total) {
      el.textContent = '✅';
    } else {
      el.textContent = '●';
    }
  }

  completeDailyQuest(id) {
    if (!this.quests) {
      this.loadDailyQuests();
    }

    if (!this.quests || !Array.isArray(this.quests.list)) return false;
    if (this.quests.completed[id]) return false;

    this.quests.completed[id] = true;

    this.game.showMessage(this.game.t('daily_completed'));
    this.updateDailyIndicator();
    this.giveDailyQuestReward(id);

    if (this.storage && typeof this.storage.saveDailyQuests === 'function') {
      this.storage.saveDailyQuests(this.quests);
    }

    return true;
  }

  giveDailyQuestReward(id) {
    if (!this.quests) return;

    const quest = this.quests.list.find((q) => q.id === id);
    if (!quest) return;

    switch (id) {
      case 'completeLevel':
        this.game.xp += 20;
        this.game.incrementStat('totalXP', 20);
        this.game.updateXPBar();
        break;
      case 'chain5':
        this.game.grantBonus('explosion', 1);
        this.game.updateBonusesUI();
        break;
      case 'xp100':
        this.game.xp += 30;
        this.game.incrementStat('totalXP', 30);
        this.game.updateXPBar();
        break;
      case 'useBonus':
        this.game.grantBonus('shuffle', 1);
        this.game.updateBonusesUI();
        break;
      case 'spinWheel':
        this.game.xp += 15;
        this.game.incrementStat('totalXP', 15);
        this.game.updateXPBar();
        break;
    }
  }
}
