/**
 * Склонення «N ходів» для коротких ігрових повідомлень (колесо, заморозка).
 * Підключення: до LostNumberGame / formatTemplate; без bundler.
 */
var TurnsPluralFormat = (function () {
  'use strict';

  function formatTurnsUk(turns) {
    const n = Math.floor(Math.abs(Number(turns)) || 0);
    const lastTwo = n % 100;
    const lastOne = n % 10;

    if (lastTwo >= 11 && lastTwo <= 14) {
      return `${n} ходів`;
    }
    if (lastOne === 1) {
      return `${n} хід`;
    }
    if (lastOne >= 2 && lastOne <= 4) {
      return `${n} ходи`;
    }
    return `${n} ходів`;
  }

  function formatTurnsRu(turns) {
    const n = Math.floor(Math.abs(Number(turns)) || 0);
    const lastTwo = n % 100;
    const lastOne = n % 10;

    if (lastTwo >= 11 && lastTwo <= 14) {
      return `${n} ходов`;
    }
    if (lastOne === 1) {
      return `${n} ход`;
    }
    if (lastOne >= 2 && lastOne <= 4) {
      return `${n} хода`;
    }
    return `${n} ходов`;
  }

  function formatTurnsEn(turns) {
    const n = Math.floor(Math.abs(Number(turns)) || 0);
    if (n === 1) return `${n} turn`;
    return `${n} turns`;
  }

  function formatForLang(lang, turns) {
    if (lang === 'ru') return formatTurnsRu(turns);
    if (lang === 'en') return formatTurnsEn(turns);
    return formatTurnsUk(turns);
  }

  return {
    formatTurnsUk,
    formatTurnsRu,
    formatTurnsEn,
    formatForLang,
  };
})();
