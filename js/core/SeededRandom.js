// SeededRandom.js — детерминированный RNG (Xorshift32)
// Использование: const rng = new SeededRandom(seed); rng.nextFloat(); rng.nextInt(max)

class SeededRandom {
  constructor(seed) {
    this.seed = seed >>> 0 || 0xa5a5a5a5;
  }

  // Xorshift32
  next() {
    let x = this.seed >>> 0;
    x ^= (x << 13) >>> 0;
    x ^= (x >>> 17) >>> 0;
    x ^= (x << 5) >>> 0;
    this.seed = x >>> 0;
    return this.seed;
  }

  nextFloat() {
    // [0,1)
    return (this.next() >>> 0) / 4294967296;
  }

  nextInt(maxExclusive) {
    const max = Math.max(1, maxExclusive | 0);
    return this.next() % max | 0;
  }

  static generateSeed() {
    try {
      const a = new Uint32Array(1);
      crypto.getRandomValues(a);
      return a[0] >>> 0 || 0xc0ffee;
    } catch (_) {
      return ((Date.now() & 0xffffffff) >>> 0) ^ 0x9e3779b9;
    }
  }

  static hashToSeed(str) {
    // FNV-1a 32-bit
    let h = 0x811c9dc5;
    const s = String(str);
    for (let i = 0; i < s.length; i++) {
      h ^= s.charCodeAt(i);
      h = Math.imul(h, 0x01000193);
    }
    return h >>> 0;
  }
}
