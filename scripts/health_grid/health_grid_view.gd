class_name HealthGridView
extends Node2D
## Draws a HealthGrid as pixel-art tiles. Purely a view: it reads the grid and
## animates feedback, and never changes a cell.

const TINT_PLAYER := Color(1.0, 0.92, 0.72)
const TINT_ENEMY := Color(1.0, 0.78, 0.74)

var grid: HealthGrid
var cell_size := 6
var gap := 0
var tint := TINT_ENEMY
var centered := true
var always_visible := false
var idle_alpha := 0.88
var backing := true
var preview: Array = []

var _tex: Dictionary = {}
var _flash: Dictionary = {}
var _pop: Dictionary = {}
var _shake := 0.0
var _emphasis := 0.0
var _visible_timer := 0.0
var _poison_t := 0.0


func setup(g: HealthGrid, size: int, is_player: bool) -> void:
	grid = g
	cell_size = size
	tint = TINT_PLAYER if is_player else TINT_ENEMY
	var p := "cell" if size >= 12 else "scell"
	for key in ["normal", "cracked", "armor", "armor_cracked", "empty", "marker"]:
		_tex[key] = Art.tex("%s_%s" % [p, key])
	_tex["poison"] = Art.slice_n("%s_poison" % p, 3 if size >= 12 else 2)
	grid.cells_hit.connect(_on_hit)
	grid.cells_destroyed.connect(_on_destroyed)
	grid.armor_broken.connect(_on_hit)
	grid.blocked.connect(_on_blocked)
	grid.poison_spread.connect(_on_hit)
	queue_redraw()


func pulse(strength := 1.0) -> void:
	_emphasis = maxf(_emphasis, strength)
	_visible_timer = 2.4


func _on_hit(coords: Array) -> void:
	for c in coords:
		_flash[c] = 0.16
		_pop[c] = 0.22
	_visible_timer = 2.4
	queue_redraw()


func _on_blocked(coords: Array) -> void:
	for c in coords:
		_flash[c] = 0.2
	_shake = maxf(_shake, 1.6)
	_visible_timer = 2.4
	queue_redraw()


func _on_destroyed(coords: Array) -> void:
	for c in coords:
		_pop[c] = 0.3
	_shake = maxf(_shake, 2.2)
	_visible_timer = 2.4
	queue_redraw()


func _process(delta: float) -> void:
	var dirty := false
	for c in _flash.keys():
		_flash[c] -= delta
		if _flash[c] <= 0.0:
			_flash.erase(c)
		dirty = true
	for c in _pop.keys():
		_pop[c] -= delta
		if _pop[c] <= 0.0:
			_pop.erase(c)
		dirty = true
	if _shake > 0.0:
		_shake = maxf(0.0, _shake - delta * 9.0)
		dirty = true
	if _emphasis > 0.0:
		_emphasis = maxf(0.0, _emphasis - delta * 2.4)
		dirty = true
	if _visible_timer > 0.0:
		_visible_timer -= delta
		dirty = true
	var pt := _poison_t
	_poison_t = fmod(_poison_t + delta, 1.0)
	if grid != null and grid.has_poison() and int(pt * 4) != int(_poison_t * 4):
		dirty = true
	if dirty:
		queue_redraw()


func grid_pixel_size() -> Vector2:
	if grid == null:
		return Vector2.ZERO
	var r := grid.used_rect()
	return Vector2(r.size.x, r.size.y) * (cell_size + gap)


func _draw() -> void:
	if grid == null:
		return
	var rect := grid.used_rect()
	if rect.size.x == 0:
		return
	var step := cell_size + gap
	var origin := Vector2.ZERO
	if centered:
		origin = -Vector2(rect.size.x, rect.size.y) * step * 0.5
	var alpha := 1.0
	if not always_visible:
		var wounded := grid.alive_count() < grid.total_count() or grid.has_poison()
		alpha = idle_alpha if (_visible_timer <= 0.0 and not wounded) else 1.0
	var scale_all := 1.0 + _emphasis * 0.25
	var jitter := Vector2(randf_range(-_shake, _shake), randf_range(-_shake, _shake)) * 0.5
	if backing:
		var pad := 1.0
		var back := Rect2(origin * scale_all + jitter - Vector2(pad, pad),
			Vector2(rect.size.x, rect.size.y) * step * scale_all + Vector2(pad, pad) * 2.0)
		draw_rect(back, Color(0.09, 0.07, 0.12, 0.55 * alpha))
	for y in rect.size.y:
		for x in rect.size.x:
			var coord := rect.position + Vector2i(x, y)
			var cell: HealthCell = grid.get_cell(coord)
			if cell == null:
				continue
			var pos := origin + Vector2(x, y) * step
			pos = (pos * scale_all) + jitter
			var size := Vector2(cell_size, cell_size) * scale_all
			var pop: float = _pop.get(coord, 0.0)
			if pop > 0.0:
				var g := pop * 10.0
				pos -= Vector2(g, g) * 0.5
				size += Vector2(g, g)
			var t: Texture2D = _tex["empty"]
			var col := Color(1, 1, 1, alpha)
			if cell.alive:
				if cell.armor > 0:
					t = _tex["armor"]
				elif cell.is_chipped():
					t = _tex["armor_cracked"]
				elif cell.is_wounded():
					t = _tex["cracked"]
					col = tint
					col.a = alpha
				else:
					t = _tex["normal"]
					col = tint
					col.a = alpha
			else:
				col = Color(1, 1, 1, alpha * 0.85)
			if _flash.has(coord):
				col = Color(1, 1, 1, alpha)
			draw_texture_rect(t, Rect2(pos, size), false, col)
			if cell.alive and cell.poison > 0:
				var frames: Array = _tex["poison"]
				var pf: Texture2D = frames[int(_poison_t * frames.size()) % frames.size()]
				draw_texture_rect(pf, Rect2(pos, size), false, Color(1, 1, 1, alpha * 0.9))
	for coord in preview:
		var cell2: HealthCell = grid.get_cell(coord)
		var p2 := origin + Vector2(coord - rect.position) * step
		var col2 := Color(1, 1, 1, 0.9) if cell2 != null and cell2.alive else Color(1, 0.5, 0.45, 0.6)
		draw_texture_rect(_tex["marker"], Rect2(p2, Vector2(cell_size, cell_size)), false, col2)
