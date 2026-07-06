extends RefCounted
class_name ThemeTokens

const COLOR_BG := Color("#08030F")
const COLOR_PANEL := Color(Color("#24122F"), 0.84)
const COLOR_PANEL_BORDER := Color(Color("#8B4D91"), 0.55)
const COLOR_CELL := Color(Color("#21142A"), 0.90)
const COLOR_BTN_BG := Color(Color("#24122F"), 0.86)
const COLOR_BTN_BORDER := Color(Color("#8B4D91"), 0.56)
const COLOR_PRIMARY := Color("#FF5FB3")
const COLOR_SECONDARY := Color("#B45CFF")
const COLOR_ACCENT := Color("#E186FF")
const COLOR_TEXT := Color("#F8EFFF")
const COLOR_MUTED := Color("#CDBBDD")
const COLOR_CELL_NUMBER := Color("#231A28")
const COLOR_PREVIEW_VALID := Color("#4DFF7A")
const COLOR_PREVIEW_INVALID := Color("#FF4D6D")
const COLOR_OVERLAY_BG := Color(Color("#08030F"), 0.94)

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

# --- Dusk (dark, default) — css/variables.css html[data-theme='dusk'] ---
const DUSK_COLOR_BG := Color("#1b1028")  # .app-background fallback / --pwa-theme-color
const DUSK_COLOR_PANEL := Color(Color("#241630"), 0.82)  # --panel-bg rgba(36,22,48,.82)
const DUSK_COLOR_PANEL_BORDER := Color(Color("#f6e8de"), 0.18)  # --panel-border
const DUSK_COLOR_CELL := Color(Color("#36283e"), 0.9)  # --cell-color rgba(54,40,62,.9)
const DUSK_COLOR_BTN_BG := Color(Color("#3f2a48"), 0.88)  # --btn-bg rgba(63,42,72,.88)
const DUSK_COLOR_BTN_BORDER := Color(Color("#f6e8de"), 0.15)  # --btn-border
const DUSK_COLOR_PRIMARY := Color("#ff6b9d")  # --primary-color
const DUSK_COLOR_SECONDARY := Color("#ff8f6b")  # --secondary-color
const DUSK_COLOR_ACCENT := Color("#ffb0a0")  # --accent-color
const DUSK_COLOR_TEXT := Color("#f6e8de")  # --text-color
const DUSK_COLOR_MUTED := Color("#d9c6b8")  # --muted-color
const DUSK_COLOR_PREVIEW_VALID := Color("#81c784")  # --preview-valid (dusk)
const DUSK_COLOR_PREVIEW_INVALID := Color("#e57373")  # --preview-invalid (dusk)

const COLOR_CHAIN_VALID := Color("#4DFF7A")
const COLOR_CHAIN_INVALID := Color("#FF4D6D")
const COLOR_CHAIN_CONTINUE := Color("#FFD966")
const DAWN_COLOR_CHAIN_VALID := Color("#2E7D32")
const DAWN_COLOR_CHAIN_INVALID := Color("#C62828")
const DAWN_COLOR_CHAIN_CONTINUE := Color("#F9A825")
const DUSK_COLOR_CHAIN_VALID := Color("#4DFF7A")
const DUSK_COLOR_CHAIN_INVALID := Color("#FF4D6D")
const DUSK_COLOR_CHAIN_CONTINUE := Color("#FFD966")

const MENU_TITLE_GRADIENT_START := Color("#FFE6FF")
const MENU_TITLE_GRADIENT_MID := Color("#FF5FB3")
const MENU_TITLE_GRADIENT_END := Color("#B45CFF")
const MENU_TITLE_GLOW := Color(Color("#FF5FE1"), 0.54)
const MENU_PRIMARY_BG_START := Color("#FF5FB3")
const MENU_PRIMARY_BG_END := Color("#B45CFF")
const MENU_PRIMARY_BORDER := Color(Color("#FFD8FF"), 0.68)
const MENU_PRIMARY_GLOW := Color(Color("#FF64C8"), 0.44)
const MENU_CHIP_BG := Color(Color("#190C2C"), 0.42)
const MENU_CHIP_BORDER := Color(Color("#FFC6FF"), 0.32)
const MENU_DOCK_BG := Color(Color("#0C0816"), 0.58)

const ICON_PINK := Color("#FF8EEA")
const ICON_VIOLET := Color("#8D6BFF")
const ICON_SOFT := Color("#FFD6FF")

const COLOR_NEON_BLUE := Color("#FF5FB3")
const COLOR_CHAIN_GLOW := Color(Color("#FF5FB3"), 0.28)
const COLOR_CHAIN_BRIGHT := Color("#FFE6FF")

const WHEEL_SECTOR_COLORS := [
	Color("#3C165F"), Color("#68246F"), Color("#2B3F8F"), Color("#7B2E72"),
	Color("#372064"), Color("#8A3B68"), Color("#1D536A"), Color("#50326F"),
]

const SPINNER_COLOR := Color("#FF5FB3")
const LOADING_TEXT_COLOR := Color("#F8EFFF")

# --- Tile palette by value — css/grid.css .cell[data-number] ---
# Progression: small pastel → mid green/teal → high orange/pink → legendary gold/neon.
const TILE_COLORS := {
	2: Color("#9BE7A3"),
	4: Color("#F0A7B3"),
	8: Color("#EED063"),
	16: Color("#83BCE9"),
	32: Color("#B093EA"),
	64: Color("#FFB347"),
	128: Color("#FF6EA8"),
	256: Color("#C77DFF"),
	512: Color("#72E5FF"),
	1024: Color("#FFE66D"),
	2048: Color("#FFFFFF"),
	4096: Color("#F6C6FF"),
}

const TILE_LEGENDARY_MIN := 128
const TILE_GOLD_RIM := Color("#FFD700")
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
const TILE_VALID_GRADIENT := [Color("#4DFF7A"), Color("#2E7D32")]
const TILE_INVALID_GRADIENT := [Color("#FF4D6D"), Color("#8B1025")]
const TILE_FROZEN_BG := Color("#BDC3C7")

const RADIUS_OVERLAY := 22
const RADIUS_PANEL := 22
const RADIUS_GRID := 16
const RADIUS_BUTTON := 22
const RADIUS_HUD := 16
const RADIUS_SMALL := 12
const TILE_RADIUS := 8
const TILE_INNER_RADIUS := 7
const RADIUS_PILL := 999

# --- Typography — css/base.css, css/ui.css (1rem = 16px) ---
const FONT_SIZE_TITLE := 26  # .settings-title 1.6rem
const FONT_SIZE_MENU_TITLE := 49  # .main-menu__title 3.05rem
const FONT_SIZE_BODY := 15  # .menu-btn ~0.95rem
const FONT_SIZE_SMALL := 13  # .goal-box / .system-toast 0.85rem
const FONT_SIZE_HUD := 12  # in-game goal/xp/level rows on narrow mobile
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