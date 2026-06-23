class GridManager {
  constructor(game) {
    this.game = game;
    this.isRendering = false;
    this.renderCount = 0;
    /** @type {HTMLElement[][]} */
    this.cellCache = [];
    ErrorHandler.info('GridManager initialized');
  }
}
