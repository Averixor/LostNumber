window.Rules = {
  isPowerOfTwo: function (n) {
    return Number.isSafeInteger(n) && n > 0 && Math.log2(n) % 1 === 0;
  },

  isAdjacent: function (a, b) {
    return Math.abs(a.x - b.x) <= 1 && Math.abs(a.y - b.y) <= 1;
  },

  baseXPByLen: function (len) {
    if (len <= 1) return 0;
    if (len === 2) return 4;
    if (len === 3) return 8;
    if (len === 4) return 12;
    if (len === 5) return 18;
    return 25;
  },

  isValidNextNumber: function (next, prev, chainSum) {
    if (next === prev) return true;
    if (next === prev * 2) return true;
    if (next === chainSum && window.Rules.isPowerOfTwo(chainSum) && chainSum >= prev) return true;
    return false;
  },

  canFinishChain: function (chain) {
    if (!chain || !chain.numbers || chain.numbers.length < 2) return false;
    const sum = chain.sum;
    const first = chain.numbers[0];
    return window.Rules.isPowerOfTwo(sum) && sum > first;
  },
};
