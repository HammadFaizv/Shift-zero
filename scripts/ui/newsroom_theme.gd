class_name NewsroomTheme
extends RefCounted

static var style: UIStyle = preload("res://data/ui/default.tres")
static var PAPER: Color = style.paper
static var DARK: Color = style.dark
static var GOLD: Color = style.gold
static var MUTED: Color = style.muted
static var STATE_COLORS: Dictionary = style.state_colors
static var _portable_font: Font


static func portable_font() -> Font:
	if _portable_font == null:
		# An explicit bundled face keeps glyphs and metrics identical on Web/native.
		_portable_font = preload("res://Assets/fonts/DejaVuSans.ttf")
	return _portable_font


static func box(color: Color, radius: int = -1, border: Color = Color.TRANSPARENT, padding: int = -1) -> StyleBoxFlat:
	radius = style.corner_radius if radius < 0 else radius
	padding = style.panel_padding if padding < 0 else padding
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.border_color = border
	style.set_border_width_all(NewsroomTheme.style.border_width)
	style.content_margin_left = padding
	style.content_margin_right = padding
	style.content_margin_top = padding
	style.content_margin_bottom = padding
	return style


static func label(text: String, font_size: int = -1, color: Color = Color.TRANSPARENT, wrap: bool = false) -> Label:
	font_size = style.default_font_size if font_size < 0 else font_size
	color = PAPER if color == Color.TRANSPARENT else color
	var result := Label.new()
	result.text = text
	result.add_theme_font_override("font", portable_font())
	result.add_theme_font_size_override("font_size", font_size)
	result.add_theme_color_override("font_color", color)
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if wrap:
		result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		result.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return result


static func button(text: String, primary: bool = false) -> Button:
	var result := Button.new()
	result.text = text
	result.add_theme_font_override("font", portable_font())
	result.custom_minimum_size.y = style.button_height
	result.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	result.pressed.connect(Sfx.click)
	var base := GOLD if primary else style.button_color
	result.add_theme_stylebox_override("normal", box(base))
	result.add_theme_stylebox_override("hover", box(base.lightened(style.button_hover_lighten)))
	result.add_theme_stylebox_override("pressed", box(base.darkened(style.button_pressed_darken)))
	result.add_theme_color_override("font_color", DARK if primary else PAPER)
	result.add_theme_color_override("font_hover_color", DARK if primary else PAPER)
	return result
