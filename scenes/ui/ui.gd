class_name Ui
extends RefCounted
## Shared UI furniture: the pixel font, panels, and grid-shape drawing.

const FONT := "res://assets/Silkscreen-Regular.ttf"
const FONT_BOLD := "res://assets/Silkscreen-Bold.ttf"
const TITLE_FONT := "res://assets/PressStart2P-Regular.ttf"

const INK := Color(0.95, 0.92, 0.86)
const DIM := Color(0.72, 0.68, 0.7)
const GOLD := Color(0.96, 0.79, 0.41)
const BAD := Color(0.86, 0.42, 0.42)
const BG := Color(0.11, 0.09, 0.14, 0.94)
const EDGE := Color(0.35, 0.29, 0.4)


static func font(bold := false) -> Font:
	return load(FONT_BOLD if bold else FONT)


static func label(text: String, size := 8, colour := INK, bold := false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font(bold))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", colour)
	l.add_theme_color_override("font_outline_color", Color(0.08, 0.06, 0.1))
	l.add_theme_constant_override("outline_size", 3)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


static func title(text: String, size := 16, colour := GOLD) -> Label:
	var l := label(text, size, colour)
	l.add_theme_font_override("font", load(TITLE_FONT))
	return l


static func panel(pos: Vector2, size: Vector2, fill := BG) -> Panel:
	var p := Panel.new()
	p.position = pos
	p.size = size
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = EDGE
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(0)
	p.add_theme_stylebox_override("panel", sb)
	return p


static func dim_layer(alpha := 0.74) -> ColorRect:
	var c := ColorRect.new()
	c.color = Color(0.07, 0.05, 0.09, alpha)
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_STOP
	return c


## Draws a bare shape (a growth or weapon pattern) as HP tiles.
static func draw_shape(ci: CanvasItem, cells: Array, origin: Vector2, cell_size := 12,
		colour := Color(1, 0.95, 0.82)) -> void:
	var tex := Art.tex("cell_normal" if cell_size >= 12 else "scell_normal")
	for c in cells:
		ci.draw_texture_rect(tex,
			Rect2(origin + Vector2(c.x, c.y) * cell_size, Vector2(cell_size, cell_size)),
			false, colour)


static func shape_pixel_size(cells: Array, cell_size := 12) -> Vector2:
	var s := Shapes.size_of(cells)
	return Vector2(s.x, s.y) * cell_size
