// I18N Theme: LostNumberGame prototype methods.

LostNumberGame.prototype.applyLanguage = function (lang) {
  try {
    this.lang = lang;
    const langAttr = lang === 'ua' ? 'uk' : lang;
    document.documentElement.lang = langAttr;
    document.title = this.t('app_title');

    this.renderStaticI18n();
    this.renderCriticalDynamicUI();
    this.scheduleNonCriticalI18nRender();
  } catch (error) {
    ErrorHandler.handle(error, { type: 'i18n', lang });
  }
};

LostNumberGame.prototype.renderStaticI18n = function () {
  try {
    document.querySelectorAll('[data-i18n]').forEach((el) => {
      const key = el.getAttribute('data-i18n');
      if (!key) return;
      el.textContent = this.t(key);
    });

    document.querySelectorAll('[data-i18n-title]').forEach((el) => {
      const key = el.getAttribute('data-i18n-title');
      if (!key) return;
      el.title = this.t(key);
    });

    document.querySelectorAll('[data-i18n-aria-label]').forEach((el) => {
      const key = el.getAttribute('data-i18n-aria-label');
      if (!key) return;
      el.setAttribute('aria-label', this.t(key));
    });
  } catch (error) {
    ErrorHandler.warn('renderStaticI18n failed', error);
  }
};

LostNumberGame.prototype.renderCriticalDynamicUI = function () {
  try {
    this.updateXPBar();
    this.updateGoal();
    if (this.wheelManager) {
      this.wheelManager.updateWheelUI();
    }
    if (this.bonusManager) {
      this.bonusManager.updateBonusesUI();
    }
    this.applyTheme();
    if (this.audioManager) {
      this.audioManager.updateSoundStateUI();
    }
    this.updateMultiplierIndicator();
  } catch (error) {
    ErrorHandler.handle(error, { type: 'ui_render', method: 'renderCriticalDynamicUI' });
  }
};

LostNumberGame.prototype.renderNonCriticalDynamicUI = function () {
  try {
    if (this.dailyQuestManager) {
      this.dailyQuestManager.renderDailyQuests();
    }
    if (this.statsManager) {
      this.statsManager.renderStats();
    }
    if (this.achievementManager) {
      this.achievementManager.renderAchievementsScreen();
    }
  } catch (error) {
    ErrorHandler.handle(error, { type: 'ui_render', method: 'renderNonCriticalDynamicUI' });
  }
};

LostNumberGame.prototype.scheduleNonCriticalI18nRender = function () {
  this._nonCriticalI18nGen = (this._nonCriticalI18nGen || 0) + 1;
  const gen = this._nonCriticalI18nGen;

  requestAnimationFrame(() => {
    const run = () => {
      if (gen !== this._nonCriticalI18nGen) return;
      this.renderNonCriticalDynamicUI();
    };
    if (typeof requestIdleCallback === 'function') {
      requestIdleCallback(run, { timeout: 1000 });
    } else {
      setTimeout(run, 0);
    }
  });
};

LostNumberGame.prototype.renderDynamicUI = function () {
  try {
    this.renderCriticalDynamicUI();
    this.renderNonCriticalDynamicUI();
  } catch (error) {
    ErrorHandler.handle(error, { type: 'ui_render', method: 'renderDynamicUI' });
  }
};

LostNumberGame.prototype.t = function (key) {
  try {
    const pack = I18N[this.lang] || I18N['ua'];
    return pack[key] || key;
  } catch (error) {
    ErrorHandler.warn('Translation failed', { key, lang: this.lang, error });
    return key;
  }
};

LostNumberGame.prototype.formatTemplate = function (key, params) {
  try {
    let text = this.t(key);
    Object.keys(params || {}).forEach((k) => {
      const v = params[k];
      text = text.replace(`{${k}}`, v == null ? '' : String(v));
    });
    return text;
  } catch (error) {
    ErrorHandler.warn('Template formatting failed', { key, params, error });
    return key;
  }
};

/** «5 ходів» / «1 хід» тощо — для freeze-повідомлень за поточною мовою. */
LostNumberGame.prototype.formatFrozenTurnsPhrase = function (turns) {
  try {
    const lang = this.lang === 'ru' ? 'ru' : this.lang === 'en' ? 'en' : 'ua';
    if (
      typeof TurnsPluralFormat !== 'undefined' &&
      typeof TurnsPluralFormat.formatForLang === 'function'
    ) {
      return TurnsPluralFormat.formatForLang(lang, turns);
    }
  } catch (error) {
    ErrorHandler.warn('formatFrozenTurnsPhrase failed', { turns, error });
  }
  const n = Math.floor(Math.abs(Number(turns)) || 0);
  return String(n);
};

LostNumberGame.prototype.applyTheme = function () {
  try {
    const root = document.documentElement;
    const theme = this.theme === 'dawn' ? 'dawn' : 'dusk';
    root.setAttribute('data-theme', theme);

    const themeColor = getComputedStyle(root).getPropertyValue('--pwa-theme-color').trim();
    if (themeColor) {
      const metaTheme = document.querySelector('meta[name="theme-color"]');
      if (metaTheme) metaTheme.setAttribute('content', themeColor);
      const metaTile = document.querySelector('meta[name="msapplication-TileColor"]');
      if (metaTile) metaTile.setAttribute('content', themeColor);
    }
  } catch (error) {
    ErrorHandler.warn('Theme application failed', { theme: this.theme, error });
  }
};
