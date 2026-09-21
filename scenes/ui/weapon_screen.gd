class_name WeaponScreen
extends Control
## Pick up a new weapon and decide which slot it replaces. Each card shows the
## shape the weapon carves, because that is what actually distinguishes them.

signal finished

const CELL := 12

var player: Player
var options: Array = []
var chosen := -1

var _cards: Array = []
var _title: Label
var _help: Label


static func create(p: Player, opts: Array) -> WeaponScreen:
	var s := WeaponScreen.new()
	s.set_script(load("res://scenes/ui/weapon_screen.gd"))
	s.player = p
	s.options = opts
	return s


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(Ui.dim_layer())
	_title = Ui.label("AN ARMOURY, LONG ABANDONED", 16, Ui.GOLD)
	_title.size = Vector2(480, 20)
	_title.position = Vector2(0, 14)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_title)
	_help = Ui.label("click a weapon, or press 1 2", 8, Ui.DIM)
	_help.size = Vector2(480, 12)
	_help.position = Vector2(0, 250)
	_help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_help)
	_build()


func _build() -> void:
	_clear_cards()
	var entries: Array = options if chosen < 0 else player.slots
	var count := entries.size()
	var card_w := 132 if chosen < 0 else 108
	var gap := 14
	var total := count * card_w + (count - 1) * gap
	var x := (480 - total) * 0.5
	for i in count:
		var w: WeaponData = entries[i]
		var card := Ui.panel(Vector2(x + i * (card_w + gap), 62), Vector2(card_w, 132))
		add_child(card)
		_cards.append(card)
		var icon := TextureRect.new()
		icon.texture = Art.tex(w.icon_name)
		icon.position = card.position + Vector2(card_w * 0.5 - 8, 10)
		icon.size = Vector2(16, 16)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(icon)
		var name_label := Ui.label(w.display_name, 8, Ui.INK)
		name_label.position = card.position + Vector2(0, 30)
		name_label.size = Vector2(card_w, 12)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(name_label)
		var stats := Ui.label("pen %d   plate %d" % [w.penetration, w.armor_break], 8, Ui.DIM)
		stats.position = card.position + Vector2(0, 100)
		stats.size = Vector2(card_w, 12)
		stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(stats)
		var key := Ui.label(str(i + 1), 8, Ui.GOLD)
		key.position = card.position + Vector2(5, 4)
		add_child(key)
		if chosen >= 0:
			var swap := Ui.label("replace", 8, Ui.BAD)
			swap.position = card.position + Vector2(0, 114)
			swap.size = Vector2(card_w, 12)
			swap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			add_child(swap)
	if chosen >= 0:
		_title.text = "WHICH SLOT?"
		_help.text = "click a slot, or press 1 2 3"
	queue_redraw()


func _clear_cards() -> void:
	for c in get_children():
		if c is Panel or (c is Label and c != _title and c != _help) or c is TextureRect:
			c.queue_free()
	_cards.clear()


func _unhandled_input(event: InputEvent) -> void:
	var limit: int = options.size() if chosen < 0 else player.slots.size()
	for i in limit:
		if Input.is_key_pressed(KEY_1 + i):
			_pick(i)
			return
	if event is InputEventMouseButton and event.pressed:
		for i in _cards.size():
			if Rect2(_cards[i].position, _cards[i].size).has_point(event.position):
				_pick(i)
				return


func _pick(i: int) -> void:
	Sfx.play("ui_confirm", -8.0)
	if chosen < 0:
		chosen = i
		await get_tree().process_frame
		_build()
		return
	player.give_weapon(options[chosen], i)
	Sfx.play("pickup", -6.0)
	finished.emit()
	queue_free()


func _draw() -> void:
	var entries: Array = options if chosen < 0 else player.slots
	for i in _cards.size():
		if i >= entries.size():
			continue
		var w: WeaponData = entries[i]
		var pattern: Array = w.pattern
		var size := Ui.shape_pixel_size(pattern, CELL)
		var at: Vector2 = _cards[i].position + Vector2((_cards[i].size.x - size.x) * 0.5, 50)
		Ui.draw_shape(self, pattern, at, CELL, HealthGridView.TINT_ENEMY)
