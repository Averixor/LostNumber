// GridManager class shell. Grid behavior is attached from js/game/grid/*.js.

class GridManager {
  constructor(game) {
    this.game = game;
    this.isRendering = false;
    this.renderCount = 0;
    ErrorHandler.info('GridManager initialized');
  }
}
