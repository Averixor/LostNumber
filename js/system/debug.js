// debug.js — определяем dev режим и утилиты
const Debug = {
  isDev() {
    try {
      const u = new URL(window.location.href);
      if (u.searchParams.get('dev') === '1') return true;
    } catch (_) {}
    const host = (location.hostname || '').toLowerCase();
    return host === 'localhost' || host === '127.0.0.1' || host.endsWith('.dev') || host.includes('cloudworkstations');
  },
};
