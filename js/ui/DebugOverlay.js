// DebugOverlay.js — Ctrl+D, показывает состояние и команды
class DebugOverlay {
  constructor(game) {
    this.game = game;
    this.visible = false;
    this.el = null;
    this.last = 0;
    this.fps = 0;
    this._frames = 0;
    this._fpsAt = performance.now();
  }

  init() {
    // показывать только в dev или если принудительно
    const allow =
      (typeof Debug !== 'undefined' && Debug.isDev()) || new URL(location.href).searchParams.get('debug') === '1';
    if (!allow) return;

    this.el = document.createElement('div');
    this.el.id = 'debugOverlay';
    this.el.style.cssText = `
      position: fixed;
      right: 10px;
      top: 10px;
      z-index: 9999;
      font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", "Courier New", monospace;
      font-size: 12px;
      line-height: 1.25;
      padding: 10px 10px;
      border-radius: 12px;
      border: 1px solid rgba(255,255,255,0.18);
      background: rgba(0,0,0,0.65);
      color: #fff;
      backdrop-filter: blur(6px);
      max-width: 320px;
      display: none;
      user-select: text;
    `;
    this.el.innerHTML = `
      <div style="display:flex;align-items:center;justify-content:space-between;gap:8px;margin-bottom:6px;">
        <strong style="font-size:12px;">DEBUG</strong>
        <button id="dbgClose" style="cursor:pointer;border:0;background:transparent;color:#fff;font-size:14px;">×</button>
      </div>
      <pre id="dbgText" style="margin:0;white-space:pre-wrap;"></pre>
      <div style="display:flex;gap:6px;flex-wrap:wrap;margin-top:8px;">
        <button id="dbgResetSeed" style="cursor:pointer;padding:6px 8px;border-radius:10px;border:1px solid rgba(255,255,255,0.2);background:rgba(255,255,255,0.1);color:#fff;">resetSeed()</button>
        <button id="dbgForceError" style="cursor:pointer;padding:6px 8px;border-radius:10px;border:1px solid rgba(255,255,255,0.2);background:rgba(255,255,255,0.1);color:#fff;">forceError()</button>
        <button id="dbgSkipLevel" style="cursor:pointer;padding:6px 8px;border-radius:10px;border:1px solid rgba(255,255,255,0.2);background:rgba(255,255,255,0.1);color:#fff;">skipLevel()</button>
      </div>
    `;
    document.body.appendChild(this.el);

    this.el.querySelector('#dbgClose').addEventListener('click', () => this.hide());
    this.el
      .querySelector('#dbgResetSeed')
      .addEventListener('click', () => this.game.resetSeed && this.game.resetSeed());
    this.el
      .querySelector('#dbgForceError')
      .addEventListener('click', () => this.game.forceError && this.game.forceError());
    this.el
      .querySelector('#dbgSkipLevel')
      .addEventListener('click', () => this.game.skipLevel && this.game.skipLevel());

    window.addEventListener(
      'keydown',
      (e) => {
        if (e.ctrlKey && (e.key === 'd' || e.key === 'D')) {
          e.preventDefault();
          this.toggle();
        }
      },
      { passive: false }
    );

    this.tick();
  }

  toggle() {
    this.visible ? this.hide() : this.show();
  }
  show() {
    if (!this.el) return;
    this.visible = true;
    this.el.style.display = 'block';
  }
  hide() {
    if (!this.el) return;
    this.visible = false;
    this.el.style.display = 'none';
  }

  tick() {
    requestAnimationFrame(() => this.tick());

    this._frames++;
    const now = performance.now();
    if (now - this._fpsAt >= 500) {
      this.fps = Math.round((this._frames * 1000) / (now - this._fpsAt));
      this._frames = 0;
      this._fpsAt = now;
    }

    if (!this.visible) return;
    if (now - this.last < 150) return;
    this.last = now;

    const g = this.game;
    const chainSum =
      typeof Chain !== 'undefined' && Chain && typeof Chain.sum === 'number' ? Chain.sum : g.activeChainSum || 0;
    const empty = g.gridManager ? g.gridManager.countEmptyCells?.() : null;

    let mem = '';
    try {
      if (performance.memory && performance.memory.usedJSHeapSize) {
        mem = (performance.memory.usedJSHeapSize / (1024 * 1024)).toFixed(1) + ' MB';
      }
    } catch (_) {}

    const text = [
      `FPS: ${this.fps}`,
      `chain.sum: ${chainSum}`,
      `lastSpinBonus: ${g.lastSpinBonus || '-'}`,
      `currentSeed: ${(g.state && g.state.currentSeed) || g.currentSeed || '-'}`,
      `levelTarget: ${g.levelTarget || '-'}`,
      `mem: ${mem || '-'}`,
      `grid.emptyCells: ${empty == null ? '-' : empty}`,
    ].join('\n');

    const pre = this.el.querySelector('#dbgText');
    if (pre) pre.textContent = text;
  }
}
