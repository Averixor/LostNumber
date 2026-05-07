const Chain = {
  numbers: [],
  sum: 0,
};

function updateChainSum() {
  Chain.sum = Chain.numbers.reduce((total, num) => total + num, 0);
}
