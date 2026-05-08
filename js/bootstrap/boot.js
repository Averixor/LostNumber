// Global handlers and game bootstrap.
// Показ критической ошибки
window.showCriticalError = function (message, errorId) {
  try {
    const container = document.getElementById('criticalErrorContainer');
    const msg = document.getElementById('criticalErrorMessage');
    const idEl = document.getElementById('criticalErrorId');

    if (container && msg) {
      msg.textContent = message || 'Произошла критическая ошибка. Обновите страницу.';
      idEl && (idEl.textContent = errorId ? 'Error ID: ' + errorId : '');
      container.style.display = 'flex';

      document.querySelectorAll('.screen, .overlay, .victory-overlay, .level-overlay, .wheel-overlay').forEach((el) => {
        if (el !== container) el.style.display = 'none';
      });
    }
  } catch (e) {
    console.error('Failed to show critical error:', e);
  }
};

/** Мінімум показу заставки (мс), щоб не «мигнула» при швидкій ініціалізації */
const SPLASH_MIN_MS = 600;

let splashShownAt = 0;

function hideLoadingScreen() {
  try {
    const overlay = document.getElementById('loadingOverlay');
    if (!overlay) return;

    const elapsed = typeof performance !== 'undefined' ? performance.now() - splashShownAt : SPLASH_MIN_MS;
    const wait = Math.max(0, SPLASH_MIN_MS - elapsed);

    setTimeout(() => {
      overlay.style.opacity = '0';
      setTimeout(() => {
        overlay.style.display = 'none';
        overlay.removeAttribute('aria-busy');
      }, 500);
    }, wait);
  } catch (_) {}
}

function showLoadingScreen() {
  const overlay = document.getElementById('loadingOverlay');
  if (overlay) {
    splashShownAt = typeof performance !== 'undefined' ? performance.now() : 0;
    overlay.style.display = 'flex';
    overlay.style.opacity = '1';
  }
}

window.addEventListener('DOMContentLoaded', () => {
  try {
    showLoadingScreen();

    setTimeout(() => {
      try {
        window.game = new LostNumberGame();
        hideLoadingScreen();
        if (typeof ErrorHandler !== 'undefined') {
          ErrorHandler.info('Game initialized successfully', { type: 'init' });
        }
      } catch (error) {
        console.error('FATAL: Game failed to initialize', error);
        hideLoadingScreen();

        const errorId = error && error.message ? error.message : String(error).substring(0, 100);
        window.showCriticalError('Игра не может быть загружена. Обновите страницу или попробуйте позже.', errorId);

        if (typeof ErrorHandler !== 'undefined') {
          ErrorHandler.handle(error, { type: 'fatal_init' });
        }
      }
    }, 100);
  } catch (error) {
    console.error('Failed to set up game initialization:', error);
    hideLoadingScreen();
    window.showCriticalError('Не удалось подготовить запуск игры. Обновите страницу.');
  }
});

// Ошибки ресурсов
window.addEventListener(
  'error',
  function (e) {
    const t = e.target;
    if (t && (t.tagName === 'IMG' || t.tagName === 'SCRIPT' || t.tagName === 'LINK')) {
      const src = t.src || t.href || '';
      if (window.AppEnv?.isDev) {
        console.warn('Resource failed to load:', src);
      }
      if (typeof ErrorHandler !== 'undefined') {
        ErrorHandler.warn('Resource failed to load: ' + src, { type: 'resource' });
      }
    }
  },
  true
);

// Состояние сети: online/offline
window.addEventListener('online', function () {
  if (window.game && typeof window.game.showMessage === 'function') {
    const msg = window.game.t ? window.game.t('online_status') : 'Соединение восстановлено';
    window.game.showMessage(msg);
  }
});

window.addEventListener('offline', function () {
  if (window.game && typeof window.game.showMessage === 'function') {
    const msg = window.game.t ? window.game.t('offline_status') : 'Режим офлайн';
    window.game.showMessage(msg);
  }
});

// Предупреждение о несохранённых данных
window.addEventListener('beforeunload', (e) => {
  try {
    if (window.game?.hasUnsavedChanges) {
      e.preventDefault();
      e.returnValue = 'Есть несохраненные изменения. Вы уверены?';
    }
  } catch (_) {}
});

// Кнопка перезагрузки на критическом экране
document.addEventListener('click', function (e) {
  if (e.target && e.target.id === 'criticalReloadBtn') {
    window.location.reload();
  }
});
