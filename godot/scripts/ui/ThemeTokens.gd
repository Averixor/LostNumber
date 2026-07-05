extends RefCounted
class_name ThemeTokens

## Design tokens extracted from the web reference (css/variables.css, css/ui.css,
## css/grid.css, css/overlays.css, css/lostnumber-icons.css, css/critical.css).
## Dusk is the default dark theme; dawn is the light theme.

# --- Dusk (dark, default) — css/variables.css html[data-theme='dusk'] ---
const COLOR_BG := Color("#1b1028")  # .app-background fallback / --pwa-theme-color
const COLOR_PANEL := Color(Color("#241630"), 0.82)  # --panel-bg rgba(36,22,48,.82)
const COLOR_PANEL_BORDER := Color(Color("#f6e8de"), 0.18)  # --panel-border
const COLOR_CELL := Color(Color("#36283e"), 0.9)  # --cell-color rgba(54,40,62,.9)
const COLOR_BTN_BG := Color(Color("#3f2a48"), 0.88)  # --btn-bg rgba(63,42,72,.88)
const COLOR_BTN_BORDER := Color(Color("#f6e8de"), 0.15)  # --btn-border
const COLOR_PRIMARY := Color("#ff6b9d")  # --primary-color
const COLOR_SECONDARY := Color("#ff8f6b")  # --secondary-color
const COLOR_ACCENT := Color("#ffb0a0")  # --accent-color
const COLOR_TEXT := Color("#f6e8de")  # --text-color
const COLOR_MUTED := Color("#d9c6b8")  # --muted-color
const COLOR_CELL_NUMBER := Color("#2a1b16")  # --cell-number-color (dusk)
const COLOR_PREVIEW_VALID := Color("#81c784")  # --preview-valid (dusk)
const COLOR_PREVIEW_INVALID := Color("#e57373")  # --preview-invalid (dusk)
const COLOR_OVERLAY_BG := Color(Color("#1a0f1b"), 0.96)  # .victory/.level/.wheel overlay (dusk)

# --- Dawn (light) — css/variables.css html[data-theme='dawn'] ---
const DAWN_COLOR_BG := Color("#fff5fb")  # --bg-color
const DAWN_COLOR_BG2 := Color("#f8ebf6")  # --bg2-color
const DAWN_COLOR_PANEL := Color(Color("#fff5ff"), 0.72)  # --panel-bg
const DAWN_COLOR_PANEL_BORDER := Color(Color("#7e409c"), 0.32)  # --panel-border
const DAWN_COLOR_CELL := Color(Color("#fff0fc"), 0.94)  # --cell-color
const DAWN_COLOR_BTN_BG := Color(Color("#ffe4f8"), 0.9)  # --btn-bg
const DAWN_COLOR_BTN_BORDER := Color(Color("#934eb2"), 0.38)  # --btn-border
const DAWN_COLOR_PRIMARY := Color("#b832d9")  # --primary-color
const DAWN_COLOR_SECONDARY := Color("#8a4dff")  # --secondary-color
const DAWN_COLOR_ACCENT := Color("#e8a0ff")  # --accent-color
const DAWN_COLOR_TEXT := Color("#2c1838")  # --text-color
const DAWN_COLOR_MUTED := Color(Color("#2c1838"), 0.78)  # --muted-color
const DAWN_COLOR_PREVIEW_VALID := Color("#2e7d32")  # --preview-valid (dawn)
const DAWN_COLOR_PREVIEW_INVALID := Color("#c62828")  # --preview-invalid (dawn)

# --- Main menu (dusk default skin) — css/ui.css .main-menu ---
const MENU_TITLE_GRADIENT_START := Color("#ffd9fb")  # --menu-title-gradient 0%
const MENU_TITLE_GRADIENT_MID := Color("#ff80ee")  # --menu-title-gradient 42%
const MENU_TITLE_GRADIENT_END := Color("#b866ff")  # --menu-title-gradient 100%
const MENU_TITLE_GLOW := Color(Color("#ff5fe1"), 0.52)  # --menu-title-glow
const MENU_PRIMARY_BG_START := Color("#ff5ba7")  # --menu-primary-bg 0%
const MENU_PRIMARY_BG_END := Color("#ff7c6f")  # --menu-primary-bg 100%
const MENU_PRIMARY_BORDER := Color(Color("#ffd8ff"), 0.64)  # --menu-primary-border
const MENU_PRIMARY_GLOW := Color(Color("#ff64c8"), 0.44)  # --menu-primary-glow
const MENU_CHIP_BG := Color(Color("#190c2c"), 0.34)  # --menu-chip-bg
const MENU_CHIP_BORDER := Color(Color("#ffc6ff"), 0.26)  # --menu-chip-border
const MENU_DOCK_BG := Color(Color("#0c0816"), 0.55)  # .main-menu__dock background

# --- Neon icons — css/lostnumber-icons.css :root ---
const ICON_PINK := Color("#ff8eea")  # --ln-icon-pink
const ICON_VIOLET := Color("#8d6bff")  # --ln-icon-violet
const ICON_SOFT := Color("#ffd6ff")  # --ln-icon-soft

# --- Chain line glow — game board chain overlay ---
const COLOR_NEON_BLUE := Color(0.2, 0.8, 1.0, 1.0)  # chain core line
const COLOR_CHAIN_GLOW := Color(0.2, 0.8, 1.0, 0.25)  # wide outer glow
const COLOR_CHAIN_BRIGHT := Color(0.6, 0.95, 1.0, 1.0)  # inner bright line

# --- Wheel sector colors (web wheel.js parity) ---
const WHEEL_SECTOR_COLORS := [
	Color("#4CAF50"),
	Color("#F44336"),
	Color("#2196F3"),
	Color("#FF9800"),
	Color("#9C27B0"),
	Color("#FFC107"),
	Color("#00BCD4"),
	Color("#607D8B"),
]

const SPINNER_COLOR := Color("#ff6b9d")  # .loading-spinner border-top-color
const LOADING_TEXT_COLOR := Color("#f6e8de")  # .loading-text

# --- Tile palette by value — css/grid.css .cell[data-number] ---
const TILE_COLORS := {
	2: Color("#9ee6a8"),
	4: Color("#f3b1b8"),
	8: Color("#f1d16a"),
	16: Color("#8fc4f5"),
	32: Color("#b9a0f2"),
	64: Color("#ffb347"),
	128: Color("#7ed957"),
	256: Color("#ff70a6"),
	512: Color("#70d6ff"),
	1024: Color("#ff9770"),
	2048: Color("#e9ff70"),
	4096: Color("#ff70e9"),
}

## 8192+ in web are gradients; [start, end] pairs (145deg linear-gradient).
const TILE_GRADIENTS := {
	8192: [Color("#b898ff"), Color("#6b4fd9")],
	16384: [Color("#ff8f6b"), Color("#ad1457")],
	32768: [Color("#7ee8ff"), Color("#0277bd")],
	65536: [Color("#c8ff9e"), Color("#2e7d32")],
	131072: [Color("#ffe082"), Color("#f57c00")],
	262144: [Color("#e1bee7"), Color("#6a1b9a")],
	524288: [Color("#ffccbc"), Color("#d84315")],
	1048576: [Color("#b2ebf2"), Color("#00838f")],
	2097152: [Color("#f8bbd0"), Color("#880e4f")],
}

## Selected tile states — css/grid.css .cell.selected.*
const TILE_SELECTED_BG := Color("#ff8f6b")  # --secondary-color fill (dusk)
const TILE_VALID_GRADIENT := [Color("#66bb6a"), Color("#2e7d32")]
const TILE_INVALID_GRADIENT := [Color("#ef5350"), Color("#b71c1c")]
const TILE_FROZEN_BG := Color("#bdc3c7")  # .cell.frozen

# --- Radii (px) — css/ui.css, css/grid.css, css/overlays.css ---
const RADIUS_OVERLAY := 20  # .victory/.level/.wheel-content
const RADIUS_PANEL := 18  # .confirm-dialog, .main-menu__dock
const RADIUS_GRID := 14  # .grid
const RADIUS_BUTTON := 14  # .menu-btn
const RADIUS_HUD := 12  # .footer-btn, .setting-item, .system-toast, .chain-sum-hud
const RADIUS_SMALL := 10  # .goal-box, .xp-bar, .bonus-btn, .wheel-result
const TILE_RADIUS := 9  # .cell
const TILE_INNER_RADIUS := 7  # .cell.selected .cell-inner
const RADIUS_PILL := 999  # chips / primary menu button (fully rounded)

# --- Typography — css/base.css, css/ui.css (1rem = 16px) ---
const FONT_SIZE_TITLE := 26  # .settings-title 1.6rem
const FONT_SIZE_MENU_TITLE := 49  # .main-menu__title 3.05rem
const FONT_SIZE_BODY := 15  # .menu-btn ~0.95rem
const FONT_SIZE_SMALL := 13  # .goal-box / .system-toast 0.85rem
const FONT_SIZE_TILE := 16  # .cell-inner clamp max 1rem
