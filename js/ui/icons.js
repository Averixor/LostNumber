/**
 * Lost Number neon SVG icons — mount via data-ln-icon="slug" on host elements.
 */
const LostNumberIcons = {
  BASE: 'assets/icons/neon/icons/',
  _imageCache: new Map(),

  resolveUrl(slug) {
    const rel = `${this.BASE}${slug}.svg`;
    try {
      return new URL(rel, document.baseURI).href;
    } catch (_) {
      return rel;
    }
  },

  _sizeClass(host) {
    const explicit = host.getAttribute('data-ln-icon-size');
    if (explicit) return `ln-icon ln-icon--${explicit}`;

    if (host.classList.contains('menu-btn__icon')) return 'ln-icon ln-icon--lg';
    if (host.closest('.menu-quick-btn--chip')) return 'ln-icon ln-icon--sm';
    if (host.closest('.menu-quick-btn')) return 'ln-icon ln-icon--sm';
    if (host.closest('.menu-dock-btn')) return 'ln-icon ln-icon--md';
    if (host.closest('.menu-account-btn')) return 'ln-icon ln-icon--sm';
    if (host.closest('.feature-stub-dialog__icon')) return 'ln-icon ln-icon--xl';
    if (host.closest('.footer-btn')) return 'ln-icon ln-icon--md';
    if (host.closest('.bonus-btn')) return 'ln-icon ln-icon--sm';
    if (host.closest('.achievement-icon')) return 'ln-icon ln-icon--xl';
    if (host.closest('.wheel-close-btn')) return 'ln-icon ln-icon--sm';
    if (host.closest('.freeze-icon-slot')) return 'ln-icon ln-icon--sm';

    return 'ln-icon ln-icon--lg';
  },

  getImage(slug) {
    if (!slug) return null;
    if (this._imageCache.has(slug)) {
      return this._imageCache.get(slug);
    }

    const img = new Image();
    img.decoding = 'async';
    img.src = this.resolveUrl(slug);
    this._imageCache.set(slug, img);
    return img;
  },

  mount(host, slug) {
    if (!host || !slug) return null;

    host.setAttribute('data-ln-icon', slug);
    const className = this._sizeClass(host);
    const muted = host.classList.contains('ln-icon--muted-slot');

    let img = host.querySelector('img.ln-icon');
    if (!img) {
      host.textContent = '';
      img = document.createElement('img');
      img.alt = '';
      img.setAttribute('aria-hidden', 'true');
      img.decoding = 'async';
      host.appendChild(img);
    }

    img.className = className + (muted ? ' ln-icon--muted' : '');
    img.src = this.resolveUrl(slug);
    return img;
  },

  setSlug(host, slug, options = {}) {
    if (!host) return;
    if (options.muted) host.classList.add('ln-icon--muted-slot');
    else host.classList.remove('ln-icon--muted-slot');
    this.mount(host, slug);
  },

  applyAll(root) {
    const scope = root && root.querySelectorAll ? root : document;
    scope.querySelectorAll('[data-ln-icon]').forEach((el) => {
      const slug = el.getAttribute('data-ln-icon');
      if (slug) this.mount(el, slug);
    });
  },

  drawCentered(ctx, slug, x, y, size) {
    if (!ctx || !slug) return false;

    const img = this.getImage(slug);
    if (!img || !img.complete || !img.naturalWidth) {
      if (img && !img.complete) {
        img.addEventListener(
          'load',
          () => {
            try {
              this.drawCentered(ctx, slug, x, y, size);
            } catch (_) {}
          },
          { once: true },
        );
      }
      return false;
    }

    const half = size / 2;
    ctx.drawImage(img, x - half, y - half, size, size);
    return true;
  },
};

if (typeof window !== 'undefined') {
  window.LostNumberIcons = LostNumberIcons;
}
