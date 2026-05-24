// DebugOverlay — Ctrl+D; увімкнено при AppEnv.isDev (dev або full).
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
    const allow = window.AppEnv?.isDev === true;
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
      max-width: min(360px, calc(100vw - 24px));
      max-height: calc(100vh - 24px);
      overflow: auto;
      display: none;
      user-select: text;
    `;
    const isFull = window.AppEnv?.isDebugFull === true;
    this.el.innerHTML = `
      <div style="display:flex;align-items:center;justify-content:space-between;gap:8px;margin-bottom:6px;">
        <strong style="font-size:12px;">DEBUG <span id="dbgModeLabel" style="opacity:.75;font-weight:600;"></span></strong>
        <button type="button" id="dbgClose" style="cursor:pointer;border:0;background:transparent;color:#fff;font-size:14px;">×</button>
      </div>
      <pre id="dbgText" style="margin:0;white-space:pre-wrap;font-size:11px;"></pre>
      <div style="display:flex;gap:6px;flex-wrap:wrap;margin-top:8px;">
        <button type="button" id="dbgResetSeed" style="cursor:pointer;padding:6px 8px;border-radius:10px;border:1px solid rgba(255,255,255,0.2);background:rgba(255,255,255,0.1);color:#fff;">seed</button>
        <button type="button" id="dbgForceError" style="cursor:pointer;padding:6px 8px;border-radius:10px;border:1px solid rgba(255,255,255,0.2);background:rgba(255,255,255,0.1);color:#fff;">err</button>
        <button type="button" id="dbgSkipLevel" style="cursor:pointer;padding:6px 8px;border-radius:10px;border:1px solid rgba(255,255,255,0.2);background:rgba(255,255,255,0.1);color:#fff;">lvl+</button>
        ${
          isFull
            ? `<button type="button" id="dbgDumpGrid" style="cursor:pointer;padding:6px 8px;border-radius:10px;border:1px solid rgba(126,252,106,.4);background:rgba(126,252,106,.12);color:#cfe;">grid</button>
        <button type="button" id="dbgCopyCtx" style="cursor:pointer;padding:6px 8px;border-radius:10px;border:1px solid rgba(126,252,106,.4);background:rgba(126,252,106,.12);color:#cfe;">copy</button>
        <button type="button" id="dbgPersist" style="cursor:pointer;padding:6px 8px;border-radius:10px;border:1px solid rgba(126,252,106,.4);background:rgba(126,252,106,.12);color:#cfe;">save=FULL</button>`
            : ''
        }
      </div>
      <div id="dbgHint" style="margin-top:8px;font-size:10px;opacity:.65;"></div>
    `;
    document.body.appendChild(this.el);

    const label = this.el.querySelector('#dbgModeLabel');
    if (label) label.textContent = `(${window.AppEnv?.debugMode || '?'})`;

    const hint = this.el.querySelector('#dbgHint');
    if (hint) {
      hint.textContent = isFull
        ? 'Senior: LN_DEBUG.help() · grid у консоль · save=FULL → localStorage'
        : 'Підказка: ?debug=full для повного режиму';
    }

    this.el.querySelector('#dbgClose')?.addEventListener('click', () => this.hide());
    this.el
      .querySelector('#dbgResetSeed')
      ?.addEventListener('click', () => this.game.resetSeed?.());
    this.el
      .querySelector('#dbgForceError')
      ?.addEventListener('click', () => this.game.forceError?.());
    this.el
      .querySelector('#dbgSkipLevel')
      ?.addEventListener('click', () => this.game.skipLevel?.());

    if (isFull) {
      this.el.querySelector('#dbgDumpGrid')?.addEventListener('click', () => {
        try {
          const g = this.game;
          const rows = [];
          for (let y = 0; y < g.GRID_H; y++) {
            let line = '';
            for (let x = 0; x < g.GRID_W; x++) {
              const n = g.grid?.[x]?.[y]?.number;
              line += n == null ? '.' : String(n).padStart(4, ' ');
            }
            rows.push(line);
          }
          console.log('[LN grid y=0 top →]\n' + rows.join('\n'));
        } catch (e) {
          console.warn('dump grid', e);
        }
      });
      this.el.querySelector('#dbgCopyCtx')?.addEventListener('click', async () => {
        try {
          const payload = {
            t: Date.now(),
            mode: window.AppEnv?.debugMode,
            ctx: typeof ErrorHandler._ctx === 'function' ? ErrorHandler._ctx() : {},
            stats:
              typeof ErrorHandler.getErrorStats === 'function' ? ErrorHandler.getErrorStats() : {},
          };
          const text = JSON.stringify(payload, null, 2);
          if (navigator.clipboard?.writeText) {
            await navigator.clipboard.writeText(text);
            this.game.showMessage?.('DEBUG: буфер обміну');
          } else {
            console.log(text);
          }
        } catch (e) {
          console.warn('copy ctx', e);
        }
      });
      this.el.querySelector('#dbgPersist')?.addEventListener('click', () => {
        try {
          window.LN_DEBUG?.persist?.('full');
          this.game.showMessage?.('DEBUG: збережено full; F5');
        } catch (_) {}
      });
    }

    window.addEventListener(
      'keydown',
      (e) => {
        if (e.ctrlKey && (e.key === 'd' || e.key === 'D')) {
          e.preventDefault();
          this.toggle();
        }
      },
      { passive: false },
    );

    if (isFull) {
      try {
        const corner = document.createElement('div');
        corner.id = 'lnDebugCorner';
        corner.textContent = 'DBG·FULL';
        corner.style.cssText =
          'position:fixed;left:0;bottom:0;z-index:9998;padding:4px 8px;font:10px/1 ui-monospace,monospace;background:rgba(80,160,60,.35);color:#e8ffe8;pointer-events:none;border-top-right-radius:8px;';
        document.body.appendChild(corner);
      } catch (_) {}
    }

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
    const isFull = window.AppEnv?.isDebugFull === true;
    const chainSum =
      typeof Chain !== 'undefined' && Chain && typeof Chain.sum === 'number'
        ? Chain.sum
        : g.activeChainSum || 0;
    const empty = g.gridManager ? g.gridManager.countEmptyCells?.() : null;

    let mem = '';
    try {
      if (performance.memory && performance.memory.usedJSHeapSize) {
        mem = (performance.memory.usedJSHeapSize / (1024 * 1024)).toFixed(1) + ' MB';
      }
    } catch (_) {}

    const levelConfig =
      typeof g.getLevelConfig === 'function' ? g.getLevelConfig(g.currentLevel) : null;
    const levelTarget = Number(levelConfig?.target);
    const minTile =
      typeof g.getMinimumSpawnTile === 'function' ? g.getMinimumSpawnTile(g.currentLevel) : null;

    const targetStr = Number.isFinite(levelTarget) ? levelTarget : '-';
    const minSpawnStr = Number.isFinite(minTile) ? minTile : '-';

    const lines = [
      `FPS: ${this.fps}`,
      `phase: ${g.gamePhase ?? '-'} screen: ${g.screenState ?? '-'}`,
      `level: ${g.currentLevel ?? '-'} target: ${targetStr} minSpawn: ${minSpawnStr}`,
      `chain.sum: ${chainSum} sel: ${g.selected?.length ?? 0}`,
      `seed: ${(g.state && g.state.currentSeed) || g.currentSeed || '-'}`,
      `emptyCells: ${empty == null ? '-' : empty}`,
      `mem: ${mem || '-'}`,
    ];

    if (isFull) {
      lines.push(
        `liteVisual: ${g.liteVisualMode ?? '-'} anim: ${g.animationEnabled !== false} float#: ${g.floatingNumbersEnabled !== false}`,
        `carry: ${g.carryNumber ?? '-'} mult: ${g.xpMultiplier ?? 1} (turns ${g.xpMultiplierTurns ?? 0})`,
      );
      try {
        const hist =
          typeof ErrorHandler.getErrorHistory === 'function' ? ErrorHandler.getErrorHistory() : [];
        const recent = hist.slice(-3);
        if (recent.length) {
          lines.push('— errors (last 3) —');
          recent.forEach((e) => lines.push(`${e.id}: ${(e.message || '').slice(0, 72)}`));
        }
      } catch (_) {}
    }

    const pre = this.el.querySelector('#dbgText');
    if (pre) pre.textContent = lines.join('\n');
  }
}
