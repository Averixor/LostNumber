extends RefCounted
class_name ThemeTokens

## Dark Neon Fantasy — base palette (design spec v2)
const BG_PRIMARY := Color("#0a0e27")
const BG_SECONDARY := Color("#141829")
const BG_TERTIARY := Color("#1a1f3a")
const NEON_PURPLE := Color("#b83dff")
const NEON_PINK := Color("#ff1b9e")
const NEON_MAGENTA := Color("#ff006e")
const NEON_GREEN := Color("#00ff6b")
const NEON_CYAN := Color("#00f0ff")
const ACCENT_GOLD := Color("#ffb800")
const ACCENT_ORANGE := Color("#ff6600")
const ACCENT_RED := Color("#ff3366")
const TEXT_PRIMARY := Color("#ffffff")
const TEXT_SECONDARY := Color("#c0b8d8")
const TEXT_MUTED := Color("#8a7a9e")

const COLOR_BG := Color("#0a0e27")
const COLOR_BG_SECONDARY := Color("#141829")
const COLOR_BG_TERTIARY := Color("#1a1f3a")
const COLOR_PANEL := Color(Color("#141829"), 0.72)
const COLOR_PANEL_BORDER := Color(Color("#b83dff"), 0.40)
const COLOR_CELL := Color(Color("#1a1f3a"), 0.92)
const COLOR_BTN_BG := Color(Color("#b83dff"), 0.10)
const COLOR_BTN_BORDER := Color("#b83dff")
const COLOR_PRIMARY := Color("#b83dff")
const COLOR_SECONDARY := Color("#ff1b9e")
const COLOR_ACCENT := Color("#00ff6b")
const COLOR_NEON_MAGENTA := Color("#ff006e")
const COLOR_NEON_BLUE := Color("#00f0ff")
const COLOR_ACCENT_GOLD := Color("#ffb800")
const COLOR_ACCENT_ORANGE := Color("#ff6600")
const COLOR_TEXT := Color("#ffffff")
const COLOR_MUTED := Color("#c0b8d8")
const COLOR_TERTIARY := Color("#8a7a9e")
const COLOR_CELL_NUMBER := Color("#0a0e27")
const COLOR_PREVIEW_VALID := Color("#00ff6b")
const COLOR_PREVIEW_INVALID := Color("#ff3366")
const COLOR_OVERLAY_BG := Color(Color("#0a0e27"), 0.88)
const COLOR_OUTLINE_GLASS := Color(Color("#ffffff"), 0.10)
const COLOR_DIVIDER := Color(Color("#b83dff"), 0.15)

const DAWN_COLOR_BG := Color("#F8ECFF")
const DAWN_COLOR_BG2 := Color("#EFE0FA")
const DAWN_COLOR_PANEL := Color(Color("#FFFFFF"), 0.72)
const DAWN_COLOR_PANEL_BORDER := Color(Color("#9B4CC5"), 0.34)
const DAWN_COLOR_CELL := Color(Color("#FFF0FC"), 0.94)
const DAWN_COLOR_BTN_BG := Color(Color("#FFE5FA"), 0.90)
const DAWN_COLOR_BTN_BORDER := Color(Color("#934EB2"), 0.40)
const DAWN_COLOR_PRIMARY := Color("#D927A7")
const DAWN_COLOR_SECONDARY := Color("#7B4DFF")
const DAWN_COLOR_ACCENT := Color("#B832D9")
const DAWN_COLOR_TEXT := Color("#2C1838")
const DAWN_COLOR_MUTED := Color(Color("#2C1838"), 0.78)
const DAWN_COLOR_PREVIEW_VALID := Color("#2E7D32")
const DAWN_COLOR_PREVIEW_INVALID := Color("#C62828")

# --- Dusk (dark default) — aligned with Dark Neon Fantasy spec ---
const DUSK_COLOR_BG := Color("#0a0e27")
const DUSK_COLOR_PANEL := Color(Color("#141829"), 0.72)
const DUSK_COLOR_PANEL_BORDER := Color(Color("#b83dff"), 0.40)
const DUSK_COLOR_CELL := Color(Color("#1a1f3a"), 0.92)
const DUSK_COLOR_BTN_BG := Color(Color("#b83dff"), 0.10)
const DUSK_COLOR_BTN_BORDER := Color("#b83dff")
const DUSK_COLOR_PRIMARY := Color("#b83dff")
const DUSK_COLOR_SECONDARY := Color("#ff1b9e")
const DUSK_COLOR_ACCENT := Color("#00ff6b")
const DUSK_COLOR_TEXT := Color("#ffffff")
const DUSK_COLOR_MUTED := Color("#c0b8d8")
const DUSK_COLOR_PREVIEW_VALID := Color("#00ff6b")
const DUSK_COLOR_PREVIEW_INVALID := Color("#ff3366")

const COLOR_CHAIN_VALID := Color("#00ff6b")
const COLOR_CHAIN_INVALID := Color("#ff3366")
const COLOR_CHAIN_CONTINUE := Color("#00f0ff")
const DAWN_COLOR_CHAIN_VALID := Color("#2E7D32")
const DAWN_COLOR_CHAIN_INVALID := Color("#C62828")
const DAWN_COLOR_CHAIN_CONTINUE := Color("#F9A825")
const DUSK_COLOR_CHAIN_VALID := Color("#00ff6b")
const DUSK_COLOR_CHAIN_INVALID := Color("#ff3366")
const DUSK_COLOR_CHAIN_CONTINUE := Color("#00f0ff")

const MENU_TITLE_GRADIENT_START := Color("#ffffff")
const MENU_TITLE_GRADIENT_MID := Color("#ff1b9e")
const MENU_TITLE_GRADIENT_END := Color("#b83dff")
const MENU_TITLE_GLOW := Color(Color("#b83dff"), 0.55)
const MENU_PRIMARY_BG_START := Color(Color("#b83dff"), 0.18)
const MENU_PRIMARY_BG_END := Color(Color("#ff1b9e"), 0.12)
const MENU_PRIMARY_BORDER := Color("#b83dff")
const MENU_PRIMARY_GLOW := Color(Color("#b83dff"), 0.45)
const MENU_SUCCESS_BG_START := Color(Color("#00ff6b"), 0.14)
const MENU_SUCCESS_BG_END := Color(Color("#00f0ff"), 0.08)
const MENU_SUCCESS_BORDER := Color("#00ff6b")
const MENU_SUCCESS_GLOW := Color(Color("#00ff6b"), 0.40)
const MENU_CHIP_BG := Color(Color("#141829"), 0.55)
const MENU_CHIP_BORDER := Color(Color("#b83dff"), 0.35)
const MENU_DOCK_BG := Color(Color("#0a0e27"), 0.65)

const ICON_PINK := Color("#ff1b9e")
const ICON_VIOLET := Color("#b83dff")
const ICON_SOFT := Color("#c0b8d8")
const ICON_GREEN := Color("#00ff6b")
const ICON_GOLD := Color("#ffb800")

const COLOR_CHAIN_GLOW := Color(Color("#00ff6b"), 0.35)
const COLOR_CHAIN_BRIGHT := Color("#00ff6b")

const WHEEL_SECTOR_COLORS := [
	Color("#00ff6b"), Color("#ff1b9e"), Color("#00f0ff"), Color("#b83dff"),
	Color("#ffb800"), Color("#ff6600"), Color("#ff006e"), Color("#7030a0"),
]

const WHEEL_RIM_GOLD := Color("#ffb800")
const WHEEL_RIM_ORANGE := Color("#ff6600")

const SPINNER_COLOR := Color("#00ff6b")
const LOADING_TEXT_COLOR := Color("#c0b8d8")

# --- Tile palette by value — tier colors (green → pink → purple → gold) ---
const TILE_COLORS := {
	2: Color("#00ff6b"),
	4: Color("#00e9b3"),
	8: Color("#00d4ff"),
	16: Color("#ff1b9e"),
	32: Color("#ff006e"),
	64: Color("#b83dff"),
	128: Color("#9030d0"),
	256: Color("#ffb800"),
	512: Color("#ff8800"),
	1024: Color("#ff6600"),
	2048: Color("#ffe066"),
	4096: Color("#ffffff"),
}

const TILE_LEGENDARY_MIN := 128
const TILE_GOLD_RIM := Color("#ffb800")
const TILE_TEXT_LIGHT := Color("#f6e8de")

## 8192+ in web are gradients; [start, end] pairs (145deg linear-gradient).
const TILE_GRADIENTS := {
	8192: [Color("#D8B6FF"), Color("#6B4FD9")],
	16384: [Color("#FF9ECF"), Color("#AD1457")],
	32768: [Color("#8EECFF"), Color("#0277BD")],
	65536: [Color("#C8FF9E"), Color("#2E7D32")],
	131072: [Color("#FFE082"), Color("#F57C00")],
	262144: [Color("#E1BEE7"), Color("#6A1B9A")],
	524288: [Color("#FFCCBC"), Color("#D84315")],
	1048576: [Color("#B2EBF2"), Color("#00838F")],
	2097152: [Color("#F8BBD0"), Color("#880E4F")],
}

const TILE_SELECTED_BG := Color(Color("#FF5FB3"), 0.0)
const TILE_VALID_GRADIENT := [Color("#00ff6b"), Color("#00d4ff")]
const TILE_INVALID_GRADIENT := [Color("#ff3366"), Color("#8B1025")]
const TILE_FROZEN_BG := Color("#BDC3C7")

const RADIUS_OVERLAY := 12
const RADIUS_PANEL := 8
const RADIUS_GRID := 8
const RADIUS_BUTTON := 8
const RADIUS_HUD := 8
const RADIUS_SMALL := 6
const TILE_RADIUS := 4
const TILE_INNER_RADIUS := 4
const RADIUS_PILL := 999

const SPACE_XS := 4
const SPACE_SM := 8
const SPACE_MD := 12
const SPACE_LG := 16
const SPACE_XL := 24
const TOUCH_TARGET_MIN := 48
const SHADOW_SOFT := 8
const SHADOW_MEDIUM := 12
const SHADOW_STRONG := 18
const GLOW_SOFT := 0.18
const GLOW_MEDIUM := 0.35
const GLOW_STRONG := 0.55

# --- Typography (design spec, mobile-first) ---
const FONT_SIZE_TITLE := 20
const FONT_SIZE_MENU_TITLE := 48
const FONT_SIZE_BODY := 14
const FONT_SIZE_SMALL := 12
const FONT_SIZE_HUD := 12
const FONT_SIZE_TILE := 28
const FONT_SIZE_CHAIN_BUBBLE := 36
const FONT_SIZE_CHIP := 12
const FONT_SIZE_XS := 10

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


## Auto-fit tile number font: mirrors css/grid.css .cell-inner clamp ratios.
static func tile_font_size_for_cell(cell_size: Vector2, digit_count: int, user_scale: float = 1.0) -> int:
	var min_dim := minf(cell_size.x, cell_size.y)
	if min_dim < 1.0:
		min_dim = 72.0

	var digits := maxi(1, digit_count)
	var height_ratio: float
	if digits <= 2:
		height_ratio = 0.24  # clamp(0.8rem, 2.4vw, 1rem) on ~72px cells
	elif digits == 3:
		height_ratio = 0.20  # .cell-value-compact upper range
	else:
		height_ratio = 0.17

	var by_height := min_dim * height_ratio
	var by_width := min_dim / (float(digits) * 0.56)
	var base := minf(by_height, by_width)
	var rem_cap := FONT_SIZE_TILE * (min_dim / 72.0)
	base = clampf(base, 8.0, minf(min_dim * 0.28, rem_cap))
	return maxi(8, int(round(base * user_scale)))


static func is_legendary_tile_value(n: int) -> bool:
	return n >= TILE_LEGENDARY_MIN


static func tile_text_color_for(face: Color, value: int) -> Color:
	if value <= 0:
		return COLOR_TEXT
	if value <= 8 or value in [256, 512, 1024, 2048]:
		return COLOR_CELL_NUMBER
	if value >= 8192:
		return COLOR_CELL_NUMBER
	if face.get_luminance() < 0.42:
		return TILE_TEXT_LIGHT
	return COLOR_TEXT


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
