class_name Hud
extends CanvasLayer
## Minimal HUD: the player's health grid top-left, weapon slots bottom-centre,
## and a room name that fades out.

var player: Player
var grid_view: HealthGridView

var _grid_panel: Panel
var _boss_panel: Panel
var _boss_name: Label
var boss_view: HealthGridView
var _slot_icons: Array[TextureRect] = []
var _slot_cds: Array[ColorRect] = []
var _room_label: Label
var _banner: Label
var _hint: Label


func _ready() -> void:
	layer = 5
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_grid_panel = Ui.panel(Vector2(6, 6), Vector2(28, 28))
	_grid_panel.name = "GridPanel"
	root.add_child(_grid_panel)

	grid_view = HealthGridView.new()
	grid_view.always_visible = true
	grid_view.centered = false
	grid_view.backing = false
	grid_view.position = Vector2(11, 11)
	root.add_child(grid_view)

	var slots_box := HBoxContainer.new()
	slots_box.add_theme_constant_override("separation", 6)
	slots_box.position = Vector2(480 * 0.5 - 39, 270 - 28)
	root.add_child(slots_box)
	for i in 3:
		var holder := Control.new()
		holder.custom_minimum_size = Vector2(22, 22)
		var bg := Ui.panel(Vector2.ZERO, Vector2(22, 22))
		holder.add_child(bg)
		var icon := TextureRect.new()
		icon.position = Vector2(3, 3)
		icon.size = Vector2(16, 16)
		icon.stretch_mode = TextureRect.STRETCH_KEEP
		holder.add_child(icon)
		var cd := ColorRect.new()
		cd.color = Color(0.1, 0.08, 0.13, 0.6)
		cd.position = Vector2(3, 3)
		cd.size = Vector2(16, 0)
		holder.add_child(cd)
		var num := Ui.label(str(i + 1), 8, Color(0.75, 0.7, 0.66))
		num.position = Vector2(2, 12)
		holder.add_child(num)
		slots_box.add_child(holder)
		_slot_icons.append(icon)
		_slot_cds.append(cd)

	_room_label = Ui.label("", 8, Color(0.92, 0.88, 0.82))
	_room_label.position = Vector2(0, 10)
	_room_label.size = Vector2(480, 12)
	_room_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_room_label)

	_banner = Ui.label("", 16, Color(1, 0.9, 0.66))
	_banner.position = Vector2(0, 112)
	_banner.size = Vector2(480, 24)
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.modulate.a = 0.0
	root.add_child(_banner)

	_hint = Ui.label("", 8, Color(0.85, 0.82, 0.78))
	_hint.position = Vector2(0, 226)
	_hint.size = Vector2(480, 12)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.modulate.a = 0.0
	root.add_child(_hint)


## A boss grid is too big to float over the arena, so it becomes the header.
func bind_boss(enemy: Enemy) -> void:
	unbind_boss()
	var root := get_child(0)
	boss_view = HealthGridView.new()
	boss_view.always_visible = true
	boss_view.centered = false
	boss_view.setup(enemy.grid, 12, false)
	var size := boss_view.grid_pixel_size()
	_boss_panel = Ui.panel(Vector2(240 - size.x * 0.5 - 5, 20), size + Vector2(10, 10))
	root.add_child(_boss_panel)
	boss_view.position = Vector2(240 - size.x * 0.5, 25)
	root.add_child(boss_view)
	_boss_name = Ui.label(String(enemy.data.name).to_upper(), 8, Ui.GOLD)
	_boss_name.position = Vector2(0, 6)
	_boss_name.size = Vector2(480, 12)
	_boss_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_boss_name)
	enemy.defeated.connect(func(_e): unbind_boss())


func unbind_boss() -> void:
	for n in [_boss_panel, _boss_name, boss_view]:
		if n != null and is_instance_valid(n):
			n.queue_free()
	_boss_panel = null
	_boss_name = null
	boss_view = null


func bind(p: Player) -> void:
	player = p
	grid_view.setup(p.grid, 6, true)
	p.weapon_switched.connect(func(_s): refresh_slots())
	refresh_slots()


func refresh_slots() -> void:
	if player == null:
		return
	for i in _slot_icons.size():
		if i >= player.slots.size():
			continue
		_slot_icons[i].texture = Art.tex(player.slots[i].icon_name)
		_slot_icons[i].modulate = Color(1, 1, 1) if i == player.slot else Color(0.6, 0.58, 0.62)


func _process(_delta: float) -> void:
	if player == null:
		return
	for i in _slot_cds.size():
		_slot_cds[i].size = Vector2(16, 16.0 * player.cooldown_ratio(i))
	var size := grid_view.grid_pixel_size()
	_grid_panel.size = size + Vector2(10, 10)


func show_room(name: String) -> void:
	_room_label.text = name
	_room_label.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_interval(2.0)
	tw.tween_property(_room_label, "modulate:a", 0.0, 0.8)


func banner(text: String, colour := Color(1, 0.9, 0.66)) -> void:
	_banner.text = text
	_banner.add_theme_color_override("font_color", colour)
	_banner.modulate.a = 1.0
	_banner.scale = Vector2(0.9, 0.9)
	var tw := create_tween()
	tw.tween_interval(1.1)
	tw.tween_property(_banner, "modulate:a", 0.0, 0.5)


func hint(text: String) -> void:
	if _hint.text == text and _hint.modulate.a > 0.5:
		return
	_hint.text = text
	var tw := create_tween()
	tw.tween_property(_hint, "modulate:a", 1.0 if text != "" else 0.0, 0.35)
