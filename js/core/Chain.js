const Chain = {
  numbers: [],
  _sum: 0,

  get sum() {
    return this.numbers.reduce((total, num) => {
      const n = Number(num);
      return Number.isFinite(n) ? total + n : total;
    }, 0);
  },

  set sum(value) {
    this._sum = Number(value) || 0;
  },
};

function updateChainSum() {
  Chain._sum = Chain.sum;
  return Chain._sum;
}
