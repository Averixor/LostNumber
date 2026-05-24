// Однослівні «чити» для консолі браузера (DevTools → Console): натиснув слово й Enter.
// Увімкнені лише коли LN_isDevToolsAllowed() (local dev або LN_BUILD_FLAGS.cheatsEnabled).
(function () {
  'use strict';

  try {
    if (window.__LN_CODES_INSTALLED__) {
      return;
    }

    if (typeof window.LN_isDevToolsAllowed !== 'function' || !window.LN_isDevToolsAllowed()) {
      return;
    }

    function getGame() {
      return window.game && typeof window.game === 'object' ? window.game : null;
    }

    function refreshGame(game) {
      try {
        if (!game) {
          return;
        }
        if (typeof game.checkWheelDailyReset === 'function') {
          game.checkWheelDailyReset();
        }
        if (typeof game.refreshLevelUI === 'function') {
          game.refreshLevelUI();
        }
        if (game.gridManager && typeof game.gridManager.render === 'function') {
          game.gridManager.render();
        }
      } catch (e) {
        console.warn('[LN_CODES] refresh', e);
      }
    }

    function ensureFreezeSystem(game) {
      try {
        if (!game || !game.gridManager) {
          return;
        }
        if (!game.freezeSystem && typeof game.gridManager.initFreezeSystem === 'function') {
          game.gridManager.initFreezeSystem();
        }
      } catch (_) {}
    }

    function setDisplayedHumanLevel(humanLevel) {
      const game = getGame();
      if (!game || !game.gridManager) {
        return undefined;
      }
      const maxIx = typeof game.MAX_LEVEL === 'number' ? game.MAX_LEVEL - 1 : 0;
      const idx = Math.max(0, Math.min(maxIx, Number(humanLevel) - 1));
      game.currentLevel = idx;
      game.gridManager.initGame(idx);
      refreshGame(game);
      if (typeof game.saveGameState === 'function') {
        game.saveGameState();
      }
      console.info('[LN_CODES] Показуваний рівень:', humanLevel, '(index)', idx);
      return idx;
    }

    let TABLE = {};

    /** @type {Record<string, () => unknown>} */
    const HANDLERS = {
      help: function () {
        console.info('[LN_CODES] Одне слово в консолі + Enter.');
        console.table(TABLE);
        return Object.keys(HANDLERS).slice().sort();
      },

      state: function () {
        const game = getGame();
        if (!game) {
          console.warn('[LN_CODES] window.game недоступна.');
          return null;
        }
        const snapshot = {
          currentLevel: game.currentLevel,
          xp: game.xp,
          gamePhase: game.gamePhase,
          screenState: game.screenState,
          bonusInventory:
            typeof game.getBonusInventorySnapshot === 'function'
              ? game.getBonusInventorySnapshot()
              : game.bonusInventory,
          wheelSpinsToday: game.wheelSpinsToday,
          lastWheelDay: game.lastWheelDay,
          maxReachedNumber: game.maxReachedNumber,
        };
        console.log('[LN_CODES]', snapshot);
        return snapshot;
      },

      save: function () {
        const game = getGame();
        if (!game || typeof game.saveGameState !== 'function') {
          console.warn('[LN_CODES] Збереження недоступне.');
          return;
        }
        game.saveGameState();
        console.info('[LN_CODES] Збережено.');
        return 'saved';
      },

      reload: function () {
        window.location.reload();
        return 'reloading';
      },

      xp: function () {
        const game = getGame();
        if (!game) {
          console.warn('[LN_CODES] немає game');
          return;
        }
        game.xp = Math.max(0, Number(game.xp || 0) + 1000);
        refreshGame(game);
        game.saveGameState?.();
        console.info('[LN_CODES] +1000 XP');
        return game.xp;
      },

      maxxp: function () {
        const game = getGame();
        if (!game) {
          return;
        }
        game.xp = Math.max(0, Number(game.xp || 0) + 10000);
        refreshGame(game);
        game.saveGameState?.();
        console.info('[LN_CODES] +10000 XP');
        return game.xp;
      },

      lvlup: function () {
        const game = getGame();
        if (!game || !game.gridManager) {
          return;
        }
        const maxIx = typeof game.MAX_LEVEL === 'number' ? game.MAX_LEVEL - 1 : 0;
        const next = Math.min(maxIx, Number(game.currentLevel || 0) + 1);
        game.currentLevel = next;
        game.gridManager.initGame(next);
        refreshGame(game);
        game.saveGameState?.();
        console.info('[LN_CODES] Level index', next);
        return next;
      },

      lvl10: function () {
        return setDisplayedHumanLevel(10);
      },

      lvl25: function () {
        return setDisplayedHumanLevel(25);
      },

      freeze: function () {
        const game = getGame();
        if (!game) {
          return;
        }
        ensureFreezeSystem(game);
        if (!game.freezeSystem || typeof game.freezeSystem.freezeRandomCell !== 'function') {
          console.warn('[LN_CODES] FreezeSystem недоступна.');
          return;
        }
        let ok = 0;
        for (let i = 0; i < 5; i++) {
          const r = game.freezeSystem.freezeRandomCell(5, 'cheat');
          if (r && r.success) {
            ok++;
          }
        }
        refreshGame(game);
        game.saveGameState?.();
        console.info('[LN_CODES] Додано заморожених комірок (спроб успішних):', ok);
        return ok;
      },

      shuffle: function () {
        const game = getGame();
        if (!game) {
          return;
        }
        game.grantBonus?.('shuffle', 5);
        refreshGame(game);
        game.saveGameState?.();
        console.info('[LN_CODES] shuffle +5');
        return game.getBonusInventorySnapshot?.();
      },

      bomb: function () {
        const game = getGame();
        if (!game) {
          return;
        }
        game.grantBonus?.('explosion', 5);
        refreshGame(game);
        game.saveGameState?.();
        console.info('[LN_CODES] explosion +5');
        return game.getBonusInventorySnapshot?.();
      },

      bonus: function () {
        const game = getGame();
        if (!game) {
          return;
        }
        game.grantBonus?.('shuffle', 3);
        game.grantBonus?.('destroy', 3);
        game.grantBonus?.('explosion', 3);
        refreshGame(game);
        game.saveGameState?.();
        console.info('[LN_CODES] Базовий набір бонусів (+3)');
        return game.getBonusInventorySnapshot?.();
      },

      freewheel: function () {
        const game = getGame();
        if (!game) {
          return;
        }
        game.wheelSpinsToday = 0;
        if (typeof game.getTodayKey === 'function') {
          game.lastWheelDay = game.getTodayKey();
        }
        if (game.wheelManager) {
          game.wheelManager.isSpinning = false;
          if (typeof game.wheelManager.updateWheelUI === 'function') {
            game.wheelManager.updateWheelUI();
          }
        }
        refreshGame(game);
        game.saveGameState?.();
        console.info('[LN_CODES] Ліміт прокруток колеса скинуто');
        return { wheelSpinsToday: game.wheelSpinsToday };
      },

      daily: function () {
        const game = getGame();
        if (!game || !game.dailyQuestManager) {
          return;
        }
        try {
          localStorage.removeItem('dailyQuests');
        } catch (_) {}
        game.dailyQuestManager.quests = null;
        if (typeof game.dailyQuestManager.loadDailyQuests === 'function') {
          game.dailyQuestManager.loadDailyQuests();
        }
        if (typeof game.dailyQuestManager.renderDailyQuests === 'function') {
          game.dailyQuestManager.renderDailyQuests();
        }
        if (typeof game.dailyQuestManager.updateDailyIndicator === 'function') {
          game.dailyQuestManager.updateDailyIndicator();
        }
        game.saveGameState?.();
        console.info('[LN_CODES] Щоденні завдання перегенеровано');
        return game.dailyQuests;
      },

      unlock: function () {
        const game = getGame();
        if (!game || !game.achievements) {
          return;
        }
        Object.keys(game.achievements).forEach(function (key) {
          const a = game.achievements[key];
          if (a && typeof a === 'object') {
            a.unlocked = true;
            if ('max' in a) {
              a.progress = typeof a.max === 'number' ? a.max : a.progress;
            }
          }
        });
        refreshGame(game);
        game.saveGameState?.();
        if (
          game.achievementManager &&
          typeof game.achievementManager.renderAchievementsScreen === 'function'
        ) {
          game.achievementManager.renderAchievementsScreen();
        }
        console.info('[LN_CODES] Усі досягнення розблоковано');
        return game.getAchievementsSnapshot?.();
      },

      wipe: function () {
        const game = getGame();
        if (!game) {
          return;
        }
        if (game.storageManager && typeof game.storageManager.clearSave === 'function') {
          game.storageManager.clearSave();
        }
        if (typeof game.startNewGame === 'function') {
          game.startNewGame();
        }
        refreshGame(game);
        console.warn('[LN_CODES] Сейв очищено, нова гра');
        return 'wiped';
      },

      godmode: function () {
        HANDLERS.maxxp();
        HANDLERS.bonus();
        HANDLERS.freewheel();
        HANDLERS.freeze();
        const game = getGame();
        if (game && typeof game.xpMultiplier === 'number') {
          game.xpMultiplier = 2;
          game.xpMultiplierTurns = Math.max(Number(game.xpMultiplierTurns || 0), 999);
          refreshGame(game);
          game.saveGameState?.();
        }
        console.info('[LN_CODES] godmode: XP+, бонуси, заморожування, multiplier');
        return 'godmode';
      },

      win: function () {
        const game = getGame();
        if (!game || typeof game.skipLevel !== 'function') {
          return;
        }
        game.skipLevel();
        refreshGame(game);
        game.saveGameState?.();
        console.info('[LN_CODES] skipLevel (DEV)');
        return 'win';
      },

      lowfps: function () {
        if (typeof window.__testLowFpsDisableFloatingNumbers === 'function') {
          window.__testLowFpsDisableFloatingNumbers();
          console.info('[LN_CODES] lowfps event dispatched');
          return 'lowfps';
        }
        console.warn('[LN_CODES] __testLowFpsDisableFloatingNumbers недоступна (потрібен dev)');
        return;
      },
    };

    TABLE = {
      help: 'Список кодів (таблиця)',
      state: 'Знімок стану',
      save: 'Зберегти у localStorage',
      reload: 'Перезавантажити сторінку',
      xp: '+1000 XP',
      maxxp: '+10000 XP',
      lvlup: 'Наступний рівень (індекс +1)',
      lvl10: 'Рівень 10 (для людини)',
      lvl25: 'Рівень 25',
      freeze: '5 випадкових заморожених клітин (FreezeSystem)',
      shuffle: '+5 shuffle',
      bomb: '+5 explosion («бомба»)',
      bonus: 'Поштовх усіх бонусів',
      freewheel: 'Скидання добового ліміту колеса',
      daily: 'Скидання щоденних квестів (storage)',
      unlock: 'Усі achievements',
      wipe: 'clearSave + startNewGame',
      godmode: 'Розширений тест-пакет',
      win: 'skipLevel() (DEV)',
      lowfps: 'Імітація low FPS для фону',
    };

    /** @param {string} word */
    function runWord(word) {
      const n = typeof word === 'string' ? word.trim().toLowerCase() : '';
      const fn = n && HANDLERS[n];
      if (typeof fn !== 'function') {
        console.warn('[LN_CODES] Невідомий код:', word);
        return undefined;
      }
      return fn();
    }

    const registered = [];

    /** @param {string} prop */
    function registerGlobalWord(prop) {
      const key = typeof prop === 'string' ? prop.trim().toLowerCase() : '';
      if (!key) {
        return;
      }

      try {
        if (
          Object.prototype.hasOwnProperty.call(window, key) &&
          !(Object.getOwnPropertyDescriptor(window, key) || {}).configurable
        ) {
          console.warn('[LN_CODES] слово зайняте браузером, пропуск:', key);
          return;
        }
      } catch (_) {}

      try {
        Object.defineProperty(window, key, {
          configurable: true,
          enumerable: true,
          get: function () {
            return runWord(key);
          },
        });
        registered.push(key);
      } catch (e) {
        console.warn('[LN_CODES] не вдалося зареєструвати', key, e);
      }
    }

    Object.keys(HANDLERS).forEach(function (k) {
      if (k.charAt(0) === '_') {
        return;
      }
      registerGlobalWord(k);
    });

    window.LN_CODES = {
      /** @param {string} name */
      run: function (name) {
        return runWord(String(name || ''));
      },
      words: registered.slice().sort(),
      help: function () {
        return HANDLERS.help();
      },
    };

    // ─── Cheat Panel UI ───
    (function buildPanel() {
      const panel = document.createElement('div');
      panel.id = 'cheatPanel';
      panel.innerHTML =
        '<div id="cheatPanelHeader"><span>🎮 CHEATS</span><button id="cheatPanelClose">&times;</button></div><div id="cheatPanelBody"></div><div id="cheatPanelLog"></div>';

      const style = document.createElement('style');
      style.textContent =
        '#cheatPanel{position:fixed;top:60px;right:12px;width:260px;background:#1a1a2e;border:1px solid #4fc3f7;border-radius:10px;z-index:99999;font-family:monospace;font-size:13px;color:#e0e0e0;box-shadow:0 4px 24px rgba(0,0,0,.6);display:none;user-select:none}' +
        '#cheatPanelHeader{display:flex;justify-content:space-between;align-items:center;padding:8px 12px;background:#0f3460;border-radius:10px 10px 0 0;cursor:move;font-weight:bold;color:#4fc3f7;font-size:14px}' +
        '#cheatPanelClose{background:none;border:none;color:#f44;font-size:20px;cursor:pointer;line-height:1;padding:0 4px}' +
        '#cheatPanelBody{display:grid;grid-template-columns:1fr 1fr;gap:4px;padding:8px}' +
        '#cheatPanelBody button{padding:6px 2px;border:none;border-radius:6px;background:#16213e;color:#e0e0e0;cursor:pointer;font-family:monospace;font-size:11px;transition:background .15s}' +
        '#cheatPanelBody button:hover{background:#1a936f}' +
        '#cheatPanelBody button:active{background:#4fc3f7;color:#000}' +
        '#cheatPanelLog{padding:4px 10px 8px;font-size:11px;color:#7cfc00;max-height:60px;overflow-y:auto;border-top:1px solid #222}' +
        '#cheatPanelLog:empty{display:none}';
      document.head.appendChild(style);

      const body = panel.querySelector('#cheatPanelBody');
      const log = panel.querySelector('#cheatPanelLog');

      const order = [
        'xp',
        'maxxp',
        'lvlup',
        'win',
        'bonus',
        'bomb',
        'shuffle',
        'freeze',
        'freewheel',
        'daily',
        'unlock',
        'godmode',
        'state',
        'save',
        'wipe',
        'reload',
      ];
      const labels = {
        xp: '+1K XP',
        maxxp: '+10K XP',
        lvlup: 'Lvl +1',
        win: 'Skip Lvl',
        bonus: 'All +3',
        bomb: 'Bomb +5',
        shuffle: 'Shuf +5',
        freeze: 'Freeze 5',
        freewheel: 'Free Wheel',
        daily: 'Reset Daily',
        unlock: 'All Achiev',
        godmode: 'God Mode',
        state: 'State',
        save: 'Save',
        wipe: 'Wipe',
        reload: 'Reload',
      };

      order.forEach(function (key) {
        if (!HANDLERS[key]) return;
        const btn = document.createElement('button');
        btn.textContent = labels[key] || key;
        btn.title = TABLE[key] || key;
        btn.addEventListener('click', function () {
          try {
            const result = HANDLERS[key]();
            log.textContent =
              '> ' +
              key +
              (result !== undefined ? ' → ' + JSON.stringify(result).substring(0, 80) : ' ✓');
          } catch (e) {
            log.textContent = '> ' + key + ' ✗ ' + e.message;
          }
        });
        body.appendChild(btn);
      });

      panel.querySelector('#cheatPanelClose').addEventListener('click', function () {
        panel.style.display = 'none';
      });

      // Drag header
      const hdr = panel.querySelector('#cheatPanelHeader');
      let dx = 0;
      let dy = 0;
      hdr.addEventListener('pointerdown', function (e) {
        if (e.target.id === 'cheatPanelClose') return;
        dx = e.clientX - panel.offsetLeft;
        dy = e.clientY - panel.offsetTop;
        function onMove(ev) {
          panel.style.left = ev.clientX - dx + 'px';
          panel.style.top = ev.clientY - dy + 'px';
          panel.style.right = 'auto';
        }
        function onUp() {
          document.removeEventListener('pointermove', onMove);
          document.removeEventListener('pointerup', onUp);
        }
        document.addEventListener('pointermove', onMove);
        document.addEventListener('pointerup', onUp);
      });

      document.body.appendChild(panel);

      function toggleCheatPanel() {
        if (typeof window.LN_isDevToolsAllowed !== 'function' || !window.LN_isDevToolsAllowed()) {
          return;
        }
        panel.style.display = panel.style.display === 'none' ? 'block' : 'none';
      }

      // Toggle: Ctrl+~ (лише коли gate дозволяє)
      document.addEventListener('keydown', function (e) {
        if (e.ctrlKey && (e.key === '~' || e.key === '`' || e.code === 'Backquote')) {
          e.preventDefault();
          toggleCheatPanel();
        }
      });

      window.LN_CODES.panel = toggleCheatPanel;
    })();

    window.__LN_CODES_INSTALLED__ = true;
    console.info(
      '%c[LN_CODES]%c увімкнено (' +
        registered.length +
        ' слів). Панель:%c ` %c(backtick) або %c LN_CODES.panel()',
      'color:#7cfc00;font-weight:bold',
      'color:inherit',
      'color:#4fc3f7',
      'color:inherit',
      'color:#4fc3f7',
    );
  } catch (e) {
    console.warn('[LN_CODES] install failed', e);
  }
})();
