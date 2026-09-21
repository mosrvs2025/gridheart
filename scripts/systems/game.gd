class_name Game
extends Node2D
## The run: build a room, fill it, wait for it to be cleared, hand out the
## reward, walk east, repeat. One boss at the end.

const TILE := RoomBuilder.TILE

static var instance: Game

var player: Player
var camera: Shaker
var hud: Hud
var room_node: Node2D
var room_info: Dictionary = {}
var room: Dictionary = {}
var enemies_left := 0
var cleared := false
var busy := false
var used_shrine := false
var used_pedestal := false

var _fade: ColorRect
var _ui_layer: CanvasLayer
var _cursor: Sprite2D
var _door_open := false
var _ended := false


## Debug entry points, handy when working on a late room: append ?room=6 (or
## &god=1) to the page URL, or pass --room=6 on a desktop build.
var debug_room := 0
var god_mode := false


func _read_debug_flags() -> void:
	var query := ""
	if OS.has_feature("web"):
		query = str(JavaScriptBridge.eval("window.location.search", true))
	else:
		query = " ".join(OS.get_cmdline_user_args())
	for part in query.replace("?", " ").replace("&", " ").replace("--", " ").split(" "):
		var bits := part.split("=")
		if bits.size() != 2:
			continue
		match bits[0]:
			"room":
				debug_room = clampi(int(bits[1]), 0, RoomsData.count() - 1)
			"god":
				god_mode = bits[1] == "1"


func _ready() -> void:
	instance = self
	randomize()
	_read_debug_flags()
	_ui_layer = CanvasLayer.new()
	_ui_layer.layer = 10
	add_child(_ui_layer)
	_fade = ColorRect.new()
	_fade.color = Color(0.07, 0.05, 0.09, 1.0)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui_layer.add_child(_fade)
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	_show_title()


static func shake(amount: float) -> void:
	if instance != null and instance.camera != null:
		instance.camera.add_trauma(amount)


# ---------------------------------------------------------------- flow
func _show_title() -> void:
	var s := MessageScreen.create(
		"GRIDHEART",
		"your health is not a number - it is a shape\nweapons cut patterns out of it\n\nWASD move    arrow keys attack in that direction\nor aim with the mouse and click    F swings where you face\nspace dodge    1 2 3 or tab for weapons",
		"press enter or click to begin", Ui.GOLD, true)
	_ui_layer.add_child(s)
	_fade.color.a = 0.0
	s.dismissed.connect(_start_run)


func _start_run() -> void:
	Run.start()
	_ended = false
	if player != null:
		player.queue_free()
	player = Player.create()
	add_child(player)
	player.died.connect(_on_player_died)
	if camera == null:
		camera = Shaker.new()
		camera.zoom = Vector2.ONE
		add_child(camera)
	camera.target = player
	camera.make_current()
	if hud == null:
		hud = Hud.new()
		hud.set_script(load("res://scenes/ui/hud.gd"))
		add_child(hud)
	hud.bind(player)
	if _cursor == null:
		_cursor = Sprite2D.new()
		_cursor.texture = Art.tex("cursor")
		_cursor.z_index = 90
		add_child(_cursor)
	player.god_mode = god_mode
	if debug_room > 0:
		# jump in with a grid worth having, so a late room is playable
		for i in debug_room:
			var rect := player.grid.used_rect()
			player.grid.attach([Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)],
				Vector2i(rect.position.x, rect.position.y - 1))
		player.give_weapon(Weapons.make(Weapons.AXE), 1)
		hud.refresh_slots()
	_load_room(debug_room)


func _load_room(index: int) -> void:
	busy = true
	await _fade_to(1.0, 0.25)
	Run.room_index = index
	room = RoomsData.get_room(index)
	if room_node != null:
		room_node.queue_free()
	hud.unbind_boss()
	room_node = Node2D.new()
	room_node.name = "Room"
	room_node.y_sort_enabled = true
	add_child(room_node)
	move_child(room_node, 0)
	room_info = RoomBuilder.build(room_node, room)
	cleared = false
	_door_open = false
	used_shrine = false
	used_pedestal = false

	player.global_position = room_info.player_start
	player.velocity = Vector2.ZERO
	camera.snap_to(player.global_position)
	var b: Rect2 = room_info.bounds
	camera.limit_left = int(b.position.x)
	camera.limit_top = int(b.position.y)
	camera.limit_right = int(b.end.x)
	camera.limit_bottom = int(b.end.y)

	_spawn_room_props()
	_room_hint()
	enemies_left = 0
	for i in room.spawns.size():
		var point: Vector2 = room_info.spawn_points.get(i + 1, room_info.player_start + Vector2(80 + i * 24, 0))
		_spawn_enemy(room.spawns[i], point)
	if enemies_left == 0:
		_on_room_cleared(false)
	hud.show_room(room.name)
	await _fade_to(0.0, 0.3)
	busy = false


## A line of teaching where it is needed, then out of the way again.
const HINTS := {
	0: "WASD move    arrows attack that way    or mouse aim and click    space dodge",
	1: "their health is the grid above them - where you strike decides which cells go",
	2: "1 2 3 change weapon - each one cuts a different shape",
	3: "archers keep their distance, so close it or take the shot",
	5: "plate holds a blow off the soft middle - the hammer opens it",
}


func _room_hint() -> void:
	var showing_for := Run.room_index
	var text: String = HINTS.get(showing_for, "")
	if text == "":
		hud.hint("")
		return
	await get_tree().create_timer(1.4).timeout
	if Run.room_index != showing_for:
		return
	hud.hint(text)
	await get_tree().create_timer(6.0).timeout
	if Run.room_index == showing_for and room.kind != "rest":
		hud.hint("")


func _spawn_room_props() -> void:
	if room_info.shrine != Vector2.ZERO:
		var s := AnimatedSprite2D.new()
		var sf := SpriteFrames.new()
		sf.set_animation_speed("default", 3.0)
		for t in Art.slice_n("shrine", 2):
			sf.add_frame("default", t)
		s.sprite_frames = sf
		s.position = room_info.shrine + Vector2(0, -8)
		s.play()
		room_node.add_child(s)
	if room_info.pedestal != Vector2.ZERO:
		var p := Sprite2D.new()
		p.texture = Art.slice_n("pedestal", 1)[0]
		p.position = room_info.pedestal
		room_node.add_child(p)


func _spawn_enemy(id: String, at: Vector2) -> void:
	var e := Enemy.create(id)
	e.global_position = at
	room_node.add_child(e)
	enemies_left += 1
	e.defeated.connect(_on_enemy_defeated)
	if EnemyData.get_data(id).get("boss", false):
		hud.bind_boss(e)
	e.grid.cells_destroyed.connect(func(c): Run.cells_destroyed += c.size())


func _on_enemy_defeated(_e: Enemy) -> void:
	enemies_left -= 1
	if enemies_left <= 0 and not cleared:
		_on_room_cleared(true)


func _on_room_cleared(announce: bool) -> void:
	cleared = true
	if announce:
		Run.rooms_cleared += 1
		Sfx.play("room_clear", -8.0)
		hud.banner("ROOM CLEAR")
	if room.kind == "boss":
		_victory()
		return
	_open_door()
	var reward: String = RoomsData.REWARDS.get(Run.room_index, "")
	if reward != "" and announce:
		await get_tree().create_timer(0.75).timeout
		_give_reward(reward)


func _open_door() -> void:
	if _door_open:
		return
	_door_open = true
	Sfx.play("door", -12.0)
	var s := Sprite2D.new()
	s.texture = RoomBuilder.tile_tex(RoomBuilder.T_DOOR_OPEN)
	s.centered = false
	s.position = Vector2(room_info.door_tile) * TILE
	s.z_index = -17
	room_node.add_child(s)


func _give_reward(kind: String) -> void:
	match kind:
		"growth":
			await _growth_screen()
		"weapon":
			await _weapon_screen()
		"heal_growth":
			await _heal_screen()
			await _growth_screen()


func _growth_screen() -> void:
	var opts := Shapes.pick_growth(3, Run.rng)
	await _run_screen(ShapeScreen.create(player, ShapeScreen.Mode.GROWTH, opts))


func _heal_screen() -> void:
	if player.grid.alive_count() >= player.grid.total_count():
		return
	var shape := Shapes.pick_heal(Run.rng, player.grid)
	if shape.is_empty():
		return
	await _run_screen(ShapeScreen.create(player, ShapeScreen.Mode.HEAL, [shape]))


func _weapon_screen() -> void:
	var pool: Array = Weapons.UNLOCKABLE.filter(func(w): return not Run.unlocked.has(w))
	if pool.is_empty():
		pool = Weapons.UNLOCKABLE.duplicate()
	pool.shuffle()
	var opts: Array = []
	for id in pool.slice(0, 2):
		opts.append(Weapons.make(id))
		Run.unlocked.append(id)
	await _run_screen(WeaponScreen.create(player, opts))


func _input(event: InputEvent) -> void:
	# with ?god=1, K clears the room - for looking at the screens that come after
	if not god_mode or not (event is InputEventKey and event.pressed and event.keycode == KEY_K):
		return
	var sweep := WeaponData.new()
	sweep.damage = 9
	sweep.penetration = 9
	sweep.armor_break = 9
	for e in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e) and e.is_alive():
			e.grid.apply_pattern(e.grid.occupied_coords(), Vector2i.ZERO, sweep)


## Puts one of the between-rooms screens up: pause, hand it the whole display,
## and give the HUD back when it closes.
func _run_screen(screen: Control) -> void:
	hud.visible = false
	_ui_layer.add_child(screen)
	screen.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	await screen.finished
	get_tree().paused = false
	hud.visible = true


func _process(delta: float) -> void:
	if _cursor != null:
		# on the keyboard there is no pointer to draw, so the reticle sits out
		# in front of the character and shows the same thing: where a swing goes
		var at := get_global_mouse_position()
		if player != null and is_instance_valid(player) and not player.aiming_with_mouse():
			at = player.aim_point()
		_cursor.global_position = at.round()
	if busy or player == null or not player.alive():
		return
	_check_interactions()
	if cleared and _door_open:
		if player.global_position.distance_to(room_info.door) < 16.0:
			_next_room()


func _check_interactions() -> void:
	if room.kind != "rest":
		return
	var hint := ""
	if not used_shrine and room_info.shrine != Vector2.ZERO \
			and player.global_position.distance_to(room_info.shrine) < 26.0:
		if player.grid.alive_count() < player.grid.total_count():
			hint = "press E at the shrine to mend your grid"
			if Input.is_action_just_pressed("confirm"):
				used_shrine = true
				hud.hint("")
				_heal_screen()
		else:
			hint = "the shrine is quiet - nothing of yours is broken"
	elif not used_pedestal and room_info.pedestal != Vector2.ZERO \
			and player.global_position.distance_to(room_info.pedestal) < 24.0:
		hint = "press E to take up a weapon"
		if Input.is_action_just_pressed("confirm"):
			used_pedestal = true
			hud.hint("")
			_weapon_screen()
	hud.hint(hint)


func _next_room() -> void:
	if busy:
		return
	if Run.room_index + 1 >= RoomsData.count():
		_victory()
		return
	_load_room(Run.room_index + 1)


func _on_player_died() -> void:
	if _ended:
		return
	_ended = true
	await get_tree().create_timer(1.1).timeout
	var s := MessageScreen.create(
		"YOUR GRID IS EMPTY",
		"%s rooms cleared in %s\n%d enemy cells broken" % [Run.rooms_cleared, Run.elapsed_text(), Run.cells_destroyed],
		"press enter or click to try again", Ui.BAD)
	_ui_layer.add_child(s)
	s.dismissed.connect(_start_run)


## The end of a run waits out any transition in progress rather than being
## dropped by it.
func _victory() -> void:
	if _ended:
		return
	_ended = true
	while busy:
		await get_tree().process_frame
	busy = true
	Sfx.play("victory", -4.0)
	await get_tree().create_timer(1.6).timeout
	var s := MessageScreen.create(
		"THE SOVEREIGN FALLS",
		"cleared in %s\n%d cells taken, %d of yours lost\nyour grid ended at %d cells" % [
			Run.elapsed_text(), Run.cells_destroyed, Run.cells_lost, player.grid.alive_count()],
		"press enter or click to run again", Ui.GOLD)
	_ui_layer.add_child(s)
	s.dismissed.connect(_start_run)


func _fade_to(alpha: float, time: float) -> void:
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", alpha, time)
	await tw.finished
