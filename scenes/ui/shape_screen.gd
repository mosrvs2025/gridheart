class_name ShapeScreen
extends Control
## The between-rooms screen where health is chosen and placed.
##
## Growth and healing are the same act: pick a shape, turn it, and decide
## where on your own body it goes.

signal finished

enum Mode { GROWTH, HEAL }

const CELL := 12

var mode := Mode.GROWTH
var player: Player
var options: Array = []
var shape: Array = []
var rotation_steps := 0
var chosen := -1
var cursor := Vector2i.ZERO

var _rect: Rect2i
var _origin: Vector2
var _cards: Array = []
var _title: Label
var _help: Label
var _painter: Control


static func create(p: Player, screen_mode: int, opts: Array) -> ShapeScreen:
	var s := ShapeScreen.new()
	s.set_script(load("res://scenes/ui/shape_screen.gd"))
	s.player = p
	s.mode = screen_mode
	s.options = opts
	return s


func _ready() -> void:
	position = Vector2.ZERO
	size = Ui.SCREEN
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(Ui.dim_layer())
	# cells are painted by a child added last, so they sit above the cards
	_painter = Control.new()
	_painter.size = Ui.SCREEN
	_painter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_painter.draw.connect(_paint)
	_title = Ui.label("", 16, Ui.GOLD)
	_title.size = Vector2(480, 20)
	_title.position = Vector2(0, 16)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_title)
	_help = Ui.label("", 8, Ui.DIM)
	_help.size = Vector2(480, 12)
	_help.position = Vector2(0, 250)
	_help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_help)
	add_child(_painter)
	if mode == Mode.GROWTH:
		_title.text = "CHOOSE YOUR GROWTH"
		_help.text = "click a shape, or press 1 2 3"
		_build_cards()
	else:
		_title.text = "MEND WHAT YOU CAN"
		chosen = 0
		shape = options[0].cells.duplicate()
		_begin_placing()


func _build_cards() -> void:
	var count := options.size()
	var card_w := 116
	var gap := 12
	var total := count * card_w + (count - 1) * gap
	var x := (480 - total) * 0.5
	for i in count:
		var card := Ui.panel(Vector2(x + i * (card_w + gap), 78), Vector2(card_w, 108))
		add_child(card)
		var name_label := Ui.label(String(options[i].name), 8, Ui.INK)
		name_label.position = Vector2(card.position.x, card.position.y + 8)
		name_label.size = Vector2(card_w, 12)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(name_label)
		var cells_label := Ui.label("+%d cells" % options[i].cells.size(), 8, Ui.DIM)
		cells_label.position = Vector2(card.position.x, card.position.y + 86)
		cells_label.size = Vector2(card_w, 12)
		cells_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(cells_label)
		var key := Ui.label(str(i + 1), 8, Ui.GOLD)
		key.position = Vector2(card.position.x + 5, card.position.y + 4)
		add_child(key)
		_cards.append(card)
	move_child(_painter, get_child_count() - 1)
	_redraw()


func _begin_placing() -> void:
	for c in _cards:
		c.queue_free()
	_cards.clear()
	for child in get_children():
		if child is Label and child != _title and child != _help:
			child.queue_free()
	move_child(_painter, get_child_count() - 1)
	_title.text = "PLACE IT" if mode == Mode.GROWTH else "PLACE THE %s" % String(options[0].name).to_upper()
	_help.text = "move with the mouse   R to turn   click to place"
	if mode == Mode.HEAL:
		_help.text += "   esc to leave it"
	_rect = player.grid.used_rect().grow(2 if mode == Mode.GROWTH else 0)
	_rect.position = _rect.position.max(Vector2i.ZERO)
	_rect.end = _rect.end.min(Vector2i(player.grid.width, player.grid.height))
	_origin = Vector2(240, 140) - Vector2(_rect.size.x, _rect.size.y) * CELL * 0.5
	cursor = _rect.position + _rect.size / 2
	_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if chosen < 0:
		for i in options.size():
			if Input.is_key_pressed(KEY_1 + i) and i < options.size():
				_choose(i)
				return
		if event is InputEventMouseButton and event.pressed:
			for i in _cards.size():
				if Rect2(_cards[i].position, _cards[i].size).has_point(event.position):
					_choose(i)
					return
		return
	if event is InputEventMouseMotion:
		var c := _cell_at(event.position)
		if c != cursor:
			cursor = c
			_redraw()
	if Input.is_action_just_pressed("rotate_shape"):
		rotation_steps += 1
		shape = Shapes.rotate(shape, 1)
		Sfx.play("ui_move", -14.0)
		_redraw()
	if mode == Mode.HEAL and Input.is_action_just_pressed("pause"):
		# a mend can always be declined, so the screen can never trap anyone
		Sfx.play("ui_back", -10.0)
		finished.emit()
		queue_free()
		return
	if (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) \
			or Input.is_action_just_pressed("confirm"):
		_try_place()


func _choose(i: int) -> void:
	chosen = i
	shape = options[i].cells.duplicate()
	Sfx.play("ui_confirm", -8.0)
	_begin_placing()


func _redraw() -> void:
	if _painter != null:
		_painter.queue_redraw()


func _cell_at(pos: Vector2) -> Vector2i:
	var local := (pos - _origin) / CELL
	return _rect.position + Vector2i(int(floor(local.x)), int(floor(local.y)))


func _placement() -> Array:
	var out := []
	for c in shape:
		out.append(cursor + c)
	return out


func _valid() -> bool:
	if mode == Mode.GROWTH:
		return player.grid.can_attach(shape, cursor)
	return player.grid.can_heal(shape, cursor)


func _try_place() -> void:
	if not _valid():
		Sfx.play("ui_back", -10.0)
		return
	if mode == Mode.GROWTH:
		player.attach_growth(shape, cursor)
	else:
		player.heal_shape(shape, cursor)
	finished.emit()
	queue_free()


func _paint() -> void:
	var ci: CanvasItem = _painter
	if chosen < 0:
		for i in _cards.size():
			var cells: Array = options[i].cells
			var size := Ui.shape_pixel_size(cells, CELL)
			var at: Vector2 = _cards[i].position + (_cards[i].size - size) * 0.5 + Vector2(0, 4)
			Ui.draw_shape(ci, cells, at, CELL, HealthGridView.TINT_PLAYER)
		return

	var normal := Art.tex("cell_normal")
	var cracked := Art.tex("cell_cracked")
	var armor := Art.tex("cell_armor")
	var empty := Art.tex("cell_empty")
	var marker := Art.tex("cell_marker")
	for y in _rect.size.y:
		for x in _rect.size.x:
			var coord := _rect.position + Vector2i(x, y)
			var at := _origin + Vector2(x, y) * CELL
			var cell: HealthCell = player.grid.get_cell(coord)
			var r := Rect2(at, Vector2(CELL, CELL))
			if cell == null:
				ci.draw_texture_rect(marker, r, false, Color(1, 1, 1, 0.17))
			elif not cell.alive:
				ci.draw_texture_rect(empty, r, false, Color(1, 1, 1, 0.9))
			elif cell.armor > 0:
				ci.draw_texture_rect(armor, r, false, Color(1, 1, 1))
			elif cell.is_wounded():
				ci.draw_texture_rect(cracked, r, false, HealthGridView.TINT_PLAYER)
			else:
				ci.draw_texture_rect(normal, r, false, HealthGridView.TINT_PLAYER)
	var ok := _valid()
	var ghost_colour := Color(0.62, 1.0, 0.7, 0.85) if ok else Color(1.0, 0.45, 0.42, 0.6)
	for c in _placement():
		var at2 := _origin + Vector2(c - _rect.position) * CELL
		ci.draw_texture_rect(normal, Rect2(at2, Vector2(CELL, CELL)), false, ghost_colour)
		ci.draw_texture_rect(marker, Rect2(at2, Vector2(CELL, CELL)), false, Color(1, 1, 1, 0.9))
