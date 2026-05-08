// debug.js — єдині прапорці з AppEnv + утиліти для всього проєкту.
const Debug = {
  mode() {
    return window.AppEnv?.debugMode || 'off';
  },

  isDev() {
    return window.AppEnv?.isDev === true;
  },

  isFull() {
    return window.AppEnv?.isDebugFull === true;
  },

  log(tag, ...args) {
    if (!this.isDev()) return;
    try {
      console.log(`[LN:${tag}]`, ...args);
    } catch (_) {}
  },

  /** Лише в режимі senior / full — детальніші траси. */
  logFull(tag, ...args) {
    if (!this.isFull()) return;
    try {
      console.log(`%c[LN:FULL:${tag}]`, 'color:#9eea6a', ...args);
    } catch (_) {}
  },

  group(tag, fn) {
    if (!this.isDev()) return;
    try {
      console.group(`[LN] ${tag}`);
      fn && fn();
      console.groupEnd();
    } catch (_) {}
  },

  table(data) {
    if (!this.isFull()) return;
    try {
      console.table(data);
    } catch (_) {}
  },

  persist(mode) {
    try {
      if (mode === 'off' || mode == null) {
        localStorage.removeItem('lostnumber_debug');
        return;
      }
      localStorage.setItem('lostnumber_debug', String(mode));
    } catch (e) {
      console.warn('[LN_DEBUG] persist failed', e);
    }
  },
};

window.Debug = Debug;

window.LN_DEBUG = {
  get mode() {
    return Debug.mode();
  },
  isDev: () => Debug.isDev(),
  isFull: () => Debug.isFull(),
  persist: (m) => Debug.persist(m),
  reload: () => window.location.reload(),
  help() {
    console.info(`LostNumber debug:
  URL:  ?debug=full | ?debug=dev | ?debug=0
  persist: LN_DEBUG.persist('full') then reload
  clear:   LN_DEBUG.persist(null) then reload
  panel:   Ctrl+D (коли дозволено)
  history: ErrorHandler.getErrorHistory()`);
  },
};
