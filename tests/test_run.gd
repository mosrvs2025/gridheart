extends Node
## Drives a whole run start to finish: every room, every reward screen, the
## boss, and the victory screen. This is the check that the game is still
## playable end to end.
##   godot --headless tests/run.tscn

var failures := 0
var game: Game
var _frames := 0
var _stage := "boot"


func ok(label: String, condition: bool) -> void:
	# stderr is unbuffered, so progress survives a watchdog kill
	printerr("  %s %s" % ["PASS" if condition else "FAIL", label])
	if not condition:
		failures += 1


func _process(_delta: float) -> void:
	_frames += 1
	if _frames > 24000:
		printerr("TIMED OUT while: %s (room %d, busy %s, cleared %s)" % [
			_stage, Run.room_index, game.busy if game else "-", game.cleared if game else "-"])
		get_tree().quit(1)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_run()


func _run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child.call_deferred(game)
	await _idle(4)
	# skip the title
	var title := _find(MessageScreen)
	ok("the title screen comes up first", title != null)
	title.dismissed.emit()
	title.queue_free()
	game._start_run()
	await _idle()

	ok("the run starts in the first room", Run.room_index == 0 and game.player != null)
	var start_cells := game.player.grid.alive_count()
	ok("the player starts with a body of %d cells" % start_cells, start_cells == 6)

	var last_index := -1
	var wounded := false
	for step in 60:
		_stage = "room %d step %d" % [Run.room_index, step]
		if game.busy:
			await _idle(4)
			continue
		var screen := _find_screen()
		if screen != null:
			await _drive_screen(screen)
			continue
		if Run.room_index == 6 and not wounded:
			# take some damage so the mending shape has somewhere to go
			wounded = true
			var hit := WeaponData.new()
			hit.damage = 1
			hit.penetration = 3
			var rect := game.player.grid.used_rect()
			game.player.grid.apply_pattern([Vector2i(0, 0), Vector2i(1, 0)], rect.position, hit)
			ok("the player can be wounded", game.player.grid.alive_count() < game.player.grid.total_count())
		if not game.cleared:
			_clear_room()
			await _idle(40)
			await get_tree().create_timer(1.6).timeout   # let the reward come up
			continue
		if game.room.kind == "boss":
			break
		if Run.room_index != last_index:
			last_index = Run.room_index
			printerr("    cleared %s, grid now %d cells" % [game.room.name,
				game.player.grid.alive_count()])
		game.player.global_position = game.room_info.door
		await _idle(30)
	ok("the run reaches the throne room", game.room.kind == "boss")
	ok("the player's grid grew along the way", game.player.grid.alive_count() > start_cells)

	# the boss is still alive here; take it apart and look for the victory screen
	_clear_room()
	# the victory screen is on a real-time timer, and headless runs far faster
	# than real time, so wait on the clock rather than on frames
	for i in 60:
		await get_tree().create_timer(0.1).timeout
		if _find(MessageScreen) != null:
			break
	var victory := _find(MessageScreen)
	ok("beating the boss ends the run", victory != null)
	if victory != null:
		ok("...on a victory screen", victory.heading.contains("SOVEREIGN"))

	printerr("")
	printerr("all checks passed" if failures == 0 else "%d CHECK(S) FAILED" % failures)
	get_tree().quit(1 if failures > 0 else 0)


## Headless runs far faster than real time, so waits that need to cover a
## timer or a tween are spent on the clock, not on frames.
func _idle(frames := 40) -> void:
	for i in frames:
		await get_tree().process_frame
	await get_tree().create_timer(0.05).timeout


func _find(type) -> Node:
	for c in game._ui_layer.get_children():
		if is_instance_of(c, type):
			return c
	return null


func _find_screen() -> Control:
	for c in game._ui_layer.get_children():
		if c is ShapeScreen or c is WeaponScreen:
			return c
	return null


## Clears whatever is in the room, the way the debug key does.
func _clear_room() -> void:
	var sweep := WeaponData.new()
	sweep.damage = 9
	sweep.penetration = 9
	sweep.armor_break = 9
	for e in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e) and e.is_alive():
			e.grid.apply_pattern(e.grid.occupied_coords(), Vector2i.ZERO, sweep)


## Answers a reward screen the way a player would.
func _drive_screen(screen: Control) -> void:
	if screen is WeaponScreen:
		screen._pick(0)
		await get_tree().process_frame
		await get_tree().process_frame
		if is_instance_valid(screen):
			screen._pick(1)
		await _idle(6)
		ok("the armoury hands over a weapon", true)
		return
	var shape: ShapeScreen = screen
	if shape.chosen < 0:
		shape._choose(0)
		await get_tree().process_frame
	var placed := false
	for y in game.player.grid.height:
		for x in game.player.grid.width:
			if placed:
				continue
			for turn in 4:
				shape.cursor = Vector2i(x, y)
				if shape._valid():
					shape._try_place()
					placed = true
					break
				shape.shape = Shapes.rotate(shape.shape, 1)
	ok("a %s shape finds somewhere legal to go" % ("mend" if shape.mode == ShapeScreen.Mode.HEAL
		else "growth"), placed)
	if not placed and is_instance_valid(shape):
		shape.finished.emit()
		shape.queue_free()
	await _idle(6)
