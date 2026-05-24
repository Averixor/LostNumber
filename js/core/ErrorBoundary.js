const ErrorBoundary = {
  wrap(obj, methodName, fallback, label) {
    try {
      if (!obj || typeof obj[methodName] !== 'function') return;
      if (obj[methodName]._isWrapped) return;

      const original = obj[methodName];

      const wrapped = function (...args) {
        try {
          return original.apply(this, args);
        } catch (e) {
          try {
            if (typeof ErrorHandler !== 'undefined') {
              ErrorHandler.handle(e, { where: label || `${methodName}` });
            } else {
              console.error(e);
            }
          } catch (_) {}
          try {
            return typeof fallback === 'function' ? fallback.apply(this, args) : fallback;
          } catch (_) {}
          return undefined;
        }
      };
      wrapped._isWrapped = true;
      wrapped._original = original;

      obj[methodName] = wrapped;
    } catch (e) {
      try {
        console.error(e);
      } catch (_) {}
    }
  },
};
