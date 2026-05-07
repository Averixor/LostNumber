// EventSystem.js — простой EventBus с приоритетами и обработкой ошибок
class EventSystem {
  constructor() {
    this._map = new Map(); // event -> [{cb, once, pr}]
    this._errorHandler = null;
  }

  setErrorHandler(handler) {
    this._errorHandler = handler;
  }

  _handleEventError(error, eventName, callback) {
    if (this._errorHandler) {
      this._errorHandler(error, { event: eventName, callback: callback.name || 'anonymous' });
    } else if (typeof ErrorHandler !== 'undefined') {
      ErrorHandler.handle(error, { type: 'event_system', event: eventName });
    } else {
      console.error(`[EventSystem] Error in event '${eventName}':`, error);
    }
  }

  on(event, callback, priority = 0) {
    if (!event || typeof callback !== 'function') {
      console.warn(`[EventSystem] Invalid on() call: event=${event}, callback=${typeof callback}`);
      return () => {};
    }

    const arr = this._map.get(event) || [];
    arr.push({ cb: callback, once: false, pr: priority | 0 });
    arr.sort((a, b) => b.pr - a.pr);
    this._map.set(event, arr);

    return () => this.off(event, callback);
  }

  once(event, callback, priority = 0) {
    if (!event || typeof callback !== 'function') {
      console.warn(`[EventSystem] Invalid once() call: event=${event}, callback=${typeof callback}`);
      return () => {};
    }

    const arr = this._map.get(event) || [];
    arr.push({ cb: callback, once: true, pr: priority | 0 });
    arr.sort((a, b) => b.pr - a.pr);
    this._map.set(event, arr);

    return () => this.off(event, callback);
  }

  off(event, callback) {
    if (!event) return;

    const arr = this._map.get(event);
    if (!arr) return;

    this._map.set(
      event,
      arr.filter((it) => it.cb !== callback)
    );
  }

  emit(event, data) {
    if (!event) {
      console.warn('[EventSystem] emit() called without event name');
      return;
    }

    const arr = this._map.get(event);
    if (!arr || !arr.length) {
      // Событие не имеет обработчиков - это нормально
      return;
    }

    // копия: чтобы можно было off внутри cb
    const copy = arr.slice();
    const errors = [];

    for (const it of copy) {
      try {
        it.cb(data);
      } catch (error) {
        errors.push(error);
        this._handleEventError(error, event, it.cb);
      }

      if (it.once) {
        try {
          this.off(event, it.cb);
        } catch (error) {
          console.warn(`[EventSystem] Failed to remove once handler for '${event}':`, error);
        }
      }
    }

    // Если были ошибки и мы в режиме разработки, можно вывести информацию
    if (errors.length > 0 && typeof ErrorHandler !== 'undefined') {
      ErrorHandler.debug(`Event '${event}' completed with ${errors.length} errors`);
    }
  }

  // === НОВЫЕ МЕТОДЫ ДЛЯ ОБРАБОТКИ ОШИБОК ===

  // Безопасный emit с возможностью продолжить при ошибках
  safeEmit(event, data, continueOnError = true) {
    try {
      this.emit(event, data);
    } catch (error) {
      this._handleEventError(error, event, null);
      if (!continueOnError) {
        throw error;
      }
    }
  }

  // Проверка наличия обработчиков для события
  hasListeners(event) {
    try {
      const arr = this._map.get(event);
      return !!(arr && arr.length > 0);
    } catch (error) {
      this._handleEventError(error, 'hasListeners', null);
      return false;
    }
  }

  // Получение количества обработчиков для события
  listenerCount(event) {
    try {
      const arr = this._map.get(event);
      return arr ? arr.length : 0;
    } catch (error) {
      this._handleEventError(error, 'listenerCount', null);
      return 0;
    }
  }

  // Удаление всех обработчиков для события
  removeAllListeners(event) {
    try {
      if (event) {
        this._map.delete(event);
      } else {
        this._map.clear();
      }
    } catch (error) {
      this._handleEventError(error, 'removeAllListeners', null);
    }
  }

  // Получение списка всех событий
  getEventNames() {
    try {
      return Array.from(this._map.keys());
    } catch (error) {
      this._handleEventError(error, 'getEventNames', null);
      return [];
    }
  }

  // Обертка для функции, которая будет вызвана при событии
  wrapFunction(event, fn, priority = 0) {
    if (typeof fn !== 'function') {
      console.warn(`[EventSystem] wrapFunction: fn is not a function`);
      return () => {};
    }

    const wrapped = (...args) => {
      try {
        return fn(...args);
      } catch (error) {
        this._handleEventError(error, event, fn);
        throw error;
      }
    };

    return this.on(event, wrapped, priority);
  }

  // Создание промиса, который разрешится при событии
  promiseFor(event, timeout = 30000) {
    return new Promise((resolve, reject) => {
      const timeoutId = setTimeout(() => {
        this.off(event, handler);
        reject(new Error(`Event '${event}' timeout after ${timeout}ms`));
      }, timeout);

      const handler = (data) => {
        clearTimeout(timeoutId);
        this.off(event, handler);
        resolve(data);
      };

      this.on(event, handler);
    });
  }

  // Дебаг информация
  debugInfo() {
    try {
      const info = {
        totalEvents: this._map.size,
        events: {},
      };

      for (const [event, handlers] of this._map.entries()) {
        info.events[event] = {
          handlerCount: handlers.length,
          priorities: handlers.map((h) => h.pr),
          hasOnceHandlers: handlers.some((h) => h.once),
        };
      }

      return info;
    } catch (error) {
      this._handleEventError(error, 'debugInfo', null);
      return { error: 'Failed to get debug info' };
    }
  }
}

// Создаем глобальный экземпляр EventSystem
if (typeof window !== 'undefined' && !window.EventBus) {
  window.EventBus = new EventSystem();

  // Настраиваем обработчик ошибок по умолчанию
  if (typeof ErrorHandler !== 'undefined') {
    window.EventBus.setErrorHandler((error, context) => {
      ErrorHandler.handle(error, {
        type: 'event_bus',
        event: context.event,
        callback: context.callback,
      });
    });
  }

  // Добавляем безопасные версии методов к глобальному EventBus
  window.EventBus.safeEmit = window.EventBus.safeEmit.bind(window.EventBus);
  window.EventBus.wrapFunction = window.EventBus.wrapFunction.bind(window.EventBus);
  window.EventBus.promiseFor = window.EventBus.promiseFor.bind(window.EventBus);
}
