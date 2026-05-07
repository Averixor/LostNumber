// I18N Theme: LostNumberGame prototype methods.

LostNumberGame.prototype.applyLanguage = function (lang) {
  try {
    this.lang = lang;
    const langAttr = lang === 'ua' ? 'uk' : lang;
    document.documentElement.lang = langAttr;
    document.title = this.t('app_title');

    this.renderStaticI18n();
    this.renderDynamicUI();
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

LostNumberGame.prototype.renderDynamicUI = function () {
  try {
    this.updateXPBar();
    this.updateGoal();
    if (this.dailyQuestManager) {
      this.dailyQuestManager.renderDailyQuests();
    }
    if (this.statsManager) {
      this.statsManager.renderStats();
    }
    if (this.wheelManager) {
      this.wheelManager.updateWheelUI();
    }
    if (this.bonusManager) {
      this.bonusManager.updateBonusesUI();
    }
    if (this.achievementManager) {
      this.achievementManager.renderAchievementsScreen();
    }
    this.applyTheme();
    if (this.audioManager) {
      this.audioManager.updateSoundStateUI();
    }
    this.updateMultiplierIndicator();
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
      text = text.replace(`{${k}}`, params[k]);
    });
    return text;
  } catch (error) {
    ErrorHandler.warn('Template formatting failed', { key, params, error });
    return key;
  }
};

LostNumberGame.prototype.applyTheme = function () {
  try {
    const root = document.documentElement;
    root.setAttribute('data-theme', this.theme || 'dusk');
  } catch (error) {
    ErrorHandler.warn('Theme application failed', { theme: this.theme, error });
  }
};
