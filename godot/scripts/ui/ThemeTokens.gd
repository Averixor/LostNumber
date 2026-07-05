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
const COLOR_CELL_NUMBER := Color("#231A28")
const COLOR_PREVIEW_VALID := Color("#81c784")  # --preview-valid (dusk)
const COLOR_PREVIEW_INVALID := Color("#e57373")  # --preview-invalid (dusk)
const COLOR_CHAIN_VALID := Color("#4DFF7A")
const COLOR_CHAIN_INVALID := Color("#FF4D6D")
const COLOR_CHAIN_CONTINUE := Color("#FFD966")
const DAWN_COLOR_CHAIN_VALID := Color("#2E7D32")
const DAWN_COLOR_CHAIN_INVALID := Color("#C62828")
const DAWN_COLOR_CHAIN_CONTINUE := Color("#F9A825")
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
# Progression: small pastel → mid green/teal → high orange/pink → legendary gold/neon.
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

const TILE_LEGENDARY_MIN := 128
const TILE_GOLD_RIM := Color("#FFD700")
const TILE_TEXT_LIGHT := Color("#f6e8de")

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
const FONT_SIZE_CHAIN_BUBBLE := 24
const FONT_SIZE_CHIP := 15

## Per-skin gothic-neon palettes (dark + light pairs, index 0–5).
const SKIN_PALETTES := [
	{
		"dark": {
			"bg": Color("#120818"), "panel": Color("#241630", 0.82),
			"primary": Color("#FF6B9D"), "secondary": Color("#FF8F6B"), "accent": Color("#FFB0A0"),
			"danger": Color("#FF3355"), "success": Color("#55FF66"),
			"glow": 1.0, "rim": Color("#D4AF37"), "crystal": Color("#B866FF"),
			"title_top": Color("#FFD9FB"), "title_mid": Color("#FF80EE"), "title_end": Color("#B866FF"),
		},
		"light": {
			"bg": Color("#FFF5FB"), "panel": Color("#FFF5FF", 0.72),
			"primary": Color("#B832D9"), "secondary": Color("#8A4DFF"), "accent": Color("#E8A0FF"),
			"danger": Color("#C62828"), "success": Color("#2E7D32"),
			"glow": 0.65, "rim": Color("#934EB2"), "crystal": Color("#E8A0FF"),
			"title_top": Color("#FFE4F8"), "title_mid": Color("#D060E8"), "title_end": Color("#934EB2"),
		},
	},
	{
		"dark": {
			"bg": Color("#0A0612"), "panel": Color("#1A1028", 0.85),
			"primary": Color("#9D4EDD"), "secondary": Color("#C77DFF"), "accent": Color("#E0AAFF"),
			"danger": Color("#FF3355"), "success": Color("#55FF66"),
			"glow": 1.1, "rim": Color("#FFD700"), "crystal": Color("#7B2CBF"),
			"title_top": Color("#E0AAFF"), "title_mid": Color("#C77DFF"), "title_end": Color("#7B2CBF"),
		},
		"light": {
			"bg": Color("#F8F0FF"), "panel": Color("#F3E8FF", 0.75),
			"primary": Color("#7B2CBF"), "secondary": Color("#9D4EDD"), "accent": Color("#C77DFF"),
			"danger": Color("#B71C1C"), "success": Color("#388E3C"),
			"glow": 0.7, "rim": Color("#7B2CBF"), "crystal": Color("#C77DFF"),
			"title_top": Color("#F3E8FF"), "title_mid": Color("#C77DFF"), "title_end": Color("#7B2CBF"),
		},
	},
	{
		"dark": {
			"bg": Color("#080510"), "panel": Color("#160E24", 0.88),
			"primary": Color("#FF4081"), "secondary": Color("#FF6E9D"), "accent": Color("#FF9EC4"),
			"danger": Color("#FF3355"), "success": Color("#55FF66"),
			"glow": 0.95, "rim": Color("#C0A060"), "crystal": Color("#FF4081"),
			"title_top": Color("#FFE0EC"), "title_mid": Color("#FF6E9D"), "title_end": Color("#AD1457"),
		},
		"light": {
			"bg": Color("#FFF0F6"), "panel": Color("#FFE8F0", 0.78),
			"primary": Color("#E91E63"), "secondary": Color("#F06292"), "accent": Color("#F8BBD0"),
			"danger": Color("#C62828"), "success": Color("#2E7D32"),
			"glow": 0.6, "rim": Color("#E91E63"), "crystal": Color("#F06292"),
			"title_top": Color("#FFE8F0"), "title_mid": Color("#F06292"), "title_end": Color("#AD1457"),
		},
	},
	{
		"dark": {
			"bg": Color("#0C0818"), "panel": Color("#1E1430", 0.84),
			"primary": Color("#00E5FF"), "secondary": Color("#18FFFF"), "accent": Color("#84FFFF"),
			"danger": Color("#FF3355"), "success": Color("#55FF66"),
			"glow": 1.15, "rim": Color("#B8860B"), "crystal": Color("#00BCD4"),
			"title_top": Color("#E0FFFF"), "title_mid": Color("#18FFFF"), "title_end": Color("#00838F"),
		},
		"light": {
			"bg": Color("#F0FAFF"), "panel": Color("#E0F7FA", 0.76),
			"primary": Color("#0097A7"), "secondary": Color("#00BCD4"), "accent": Color("#80DEEA"),
			"danger": Color("#C62828"), "success": Color("#388E3C"),
			"glow": 0.65, "rim": Color("#0097A7"), "crystal": Color("#00BCD4"),
			"title_top": Color("#E0F7FA"), "title_mid": Color("#00BCD4"), "title_end": Color("#006064"),
		},
	},
	{
		"dark": {
			"bg": Color("#100818"), "panel": Color("#221830", 0.86),
			"primary": Color("#EA80FC"), "secondary": Color("#CE93D8"), "accent": Color("#F3E5F5"),
			"danger": Color("#FF3355"), "success": Color("#55FF66"),
			"glow": 1.05, "rim": Color("#DAA520"), "crystal": Color("#AB47BC"),
			"title_top": Color("#F3E5F5"), "title_mid": Color("#EA80FC"), "title_end": Color("#6A1B9A"),
		},
		"light": {
			"bg": Color("#FAF0FF"), "panel": Color("#F3E5F5", 0.74),
			"primary": Color("#8E24AA"), "secondary": Color("#AB47BC"), "accent": Color("#CE93D8"),
			"danger": Color("#B71C1C"), "success": Color("#388E3C"),
			"glow": 0.68, "rim": Color("#8E24AA"), "crystal": Color("#AB47BC"),
			"title_top": Color("#F3E5F5"), "title_mid": Color("#AB47BC"), "title_end": Color("#6A1B9A"),
		},
	},
	{
		"dark": {
			"bg": Color("#06040C"), "panel": Color("#140E20", 0.9),
			"primary": Color("#FF5252"), "secondary": Color("#FF867C"), "accent": Color("#FFAB91"),
			"danger": Color("#FF3355"), "success": Color("#55FF66"),
			"glow": 1.2, "rim": Color("#FFD700"), "crystal": Color("#FF5252"),
			"title_top": Color("#FFECB3"), "title_mid": Color("#FF867C"), "title_end": Color("#BF360C"),
		},
		"light": {
			"bg": Color("#FFF8F0"), "panel": Color("#FFF3E0", 0.76),
			"primary": Color("#E64A19"), "secondary": Color("#FF7043"), "accent": Color("#FFAB91"),
			"danger": Color("#C62828"), "success": Color("#2E7D32"),
			"glow": 0.62, "rim": Color("#E64A19"), "crystal": Color("#FF7043"),
			"title_top": Color("#FFF3E0"), "title_mid": Color("#FF7043"), "title_end": Color("#BF360C"),
		},
	},
]


## Auto-fit tile number font: scales with cell size and digit count, then user scale.
static func tile_font_size_for_cell(cell_size: Vector2, digit_count: int, user_scale: float = 1.0) -> int:
	var min_dim := minf(cell_size.x, cell_size.y)
	if min_dim < 1.0:
		min_dim = 72.0

	var digits := maxi(1, digit_count)
	var height_ratio: float
	if digits <= 2:
		height_ratio = 0.78
	elif digits == 3:
		height_ratio = 0.64
	else:
		height_ratio = 0.52

	var by_height := min_dim * height_ratio
	var by_width := min_dim / (float(digits) * 0.58)
	var base := minf(by_height, by_width)
	base = clampf(base, 8.0, min_dim * 0.85)
	return maxi(8, int(round(base * user_scale)))


static func is_legendary_tile_value(n: int) -> bool:
	return n >= TILE_LEGENDARY_MIN


static func tile_text_color_for(face: Color, value: int) -> Color:
	if value >= 8192:
		return Color.WHITE
	if face.get_luminance() < 0.42:
		return TILE_TEXT_LIGHT
	return COLOR_CELL_NUMBER


static func get_skin_palette(index: int, dark: bool) -> Dictionary:
	var idx := index
	if SKIN_PALETTES.size() > 0:
		idx = ((index % SKIN_PALETTES.size()) + SKIN_PALETTES.size()) % SKIN_PALETTES.size()
	var entry: Dictionary = SKIN_PALETTES[idx]
	return entry["dark"] if dark else entry["light"]


static func wheel_colors_for_palette(palette: Dictionary) -> Array[Color]:
	return [
		palette.get("success", COLOR_CHAIN_VALID),
		palette.get("primary", COLOR_PRIMARY),
		palette.get("secondary", COLOR_SECONDARY),
		palette.get("accent", COLOR_ACCENT),
		palette.get("danger", COLOR_CHAIN_INVALID),
		palette.get("crystal", COLOR_PRIMARY),
		Color(palette.get("rim", COLOR_ACCENT), 0.85),
		Color(palette.get("bg", COLOR_BG), 0.9).lightened(0.35),
	]
