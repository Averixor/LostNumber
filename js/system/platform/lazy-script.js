(function () {
  const cache = Object.create(null);

  window.LN_loadScriptOnce = function (src) {
    if (cache[src]) return cache[src];
    cache[src] = new Promise(function (resolve, reject) {
      const el = document.createElement('script');
      el.src = src;
      el.async = true;
      el.onload = function () {
        resolve();
      };
      el.onerror = function () {
        delete cache[src];
        reject(new Error('Failed to load script: ' + src));
      };
      document.head.appendChild(el);
    });
    return cache[src];
  };
})();
