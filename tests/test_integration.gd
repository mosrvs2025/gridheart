extends Node
## Drives real Player and Enemy nodes through a few attacks, so the whole
## chain gets exercised: swing -> world-space hit -> resolver -> grid.
##   godot --headless tests/integration.tscn

var failures := 0


func ok(label: String, condition: bool) -> void:
	print("  %s %s" % ["PASS" if condition else "FAIL", label])
	if not condition:
		failures += 1


func _ready() -> void:
	_run()


func _run() -> void:
	var stage := Node2D.new()
	add_child(stage)

	var player := Player.create()
	stage.add_child(player)
	player.global_position = Vector2.ZERO

	var goblin := Enemy.create("goblin")
	stage.add_child(goblin)
	goblin.global_position = Vector2(24, 0)
	await get_tree().process_frame

	print("\nthe swing reaches the grid")
	var before := goblin.grid.alive_count()
	player.aim = Vector2.RIGHT
	player._attack_dir = Vector2.RIGHT
	player._land_attack()
	await get_tree().process_frame
	ok("a sword swing at 24px connects", goblin.grid.alive_count() < before)
	ok("...and takes a row of cells", before - goblin.grid.alive_count() >= 3)

	print("\nout of reach is a miss")
	var far := Enemy.create("goblin")
	stage.add_child(far)
	far.global_position = Vector2(120, 0)
	await get_tree().process_frame
	var far_before := far.grid.alive_count()
	player._attack_dir = Vector2.RIGHT
	player._land_attack()
	await get_tree().process_frame
	ok("a swing at 120px hits nothing", far.grid.alive_count() == far_before)

	print("\nthe knight's plate actually stops a sword")
	var knight := Enemy.create("knight")
	stage.add_child(knight)
	knight.global_position = Vector2(-24, 0)
	await get_tree().process_frame
	var kb := knight.grid.alive_count()
	player._attack_dir = Vector2.LEFT
	player._land_attack()
	await get_tree().process_frame
	ok("the armoured face holds against the first swing", knight.grid.alive_count() == kb)
	ok("...and the plate stops the blow reaching the soft middle",
		knight.grid.get_cell(Vector2i(1, 1)).alive)
	player.slot = 2  # hammer
	for i in 3:
		player._attack_dir = Vector2.LEFT
		player._land_attack()
		await get_tree().process_frame
	ok("the hammer gets through", knight.grid.alive_count() < kb)

	print("\nan enemy strike eats the player's grid")
	var pb := player.grid.alive_count()
	var gob_attack := Weapons.enemy_attack("goblin_cut")
	player.take_hit(gob_attack, Vector2.LEFT, player.global_position + Vector2(20, 0), goblin)
	await get_tree().process_frame
	ok("being hit costs cells", player.grid.alive_count() < pb)
	ok("...and grants a moment of mercy", player.invuln > 0.0)
	var pb2 := player.grid.alive_count()
	player.take_hit(gob_attack, Vector2.LEFT, player.global_position + Vector2(20, 0), goblin)
	ok("a second hit inside the mercy window does nothing", player.grid.alive_count() == pb2)

	print("\nan emptied grid is a death")
	var slime := Enemy.create("slime")
	stage.add_child(slime)
	slime.global_position = Vector2(0, 26)
	await get_tree().process_frame
	# GDScript lambdas capture locals by value, so use a shared array as the flag.
	var killed := [false]
	slime.defeated.connect(func(_e): killed[0] = true)
	player.slot = 0
	# A downward sword takes one column at a time, so the player has to move
	# along the body to finish it - exactly the point of the system.
	for i in 14:
		slime.global_position = player.global_position + Vector2(8 - (i % 3) * 8, 26)
		slime.knockback = Vector2.ZERO
		slime.hitstop = 0.0
		player._attack_dir = Vector2.DOWN
		player._land_attack()
		await get_tree().process_frame
	ok("a slime dies once every cell is gone", killed[0] and slime.grid.alive_count() == 0)

	print("\nan emptied player grid ends the run")
	var died := [false]
	player.died.connect(func(): died[0] = true)
	var wipe := WeaponData.new()
	wipe.damage = 9
	wipe.penetration = 9
	wipe.armor_break = 9
	player.grid.apply_pattern(player.grid.occupied_coords(), Vector2i.ZERO, wipe)
	await get_tree().process_frame
	ok("the player dies when the last cell goes", died[0] and not player.alive())

	print("\nthe keyboard aims and swings on its own")
	var kp := Player.create()
	stage.add_child(kp)
	kp.global_position = Vector2(0, -200)
	await get_tree().process_frame
	ok("the aim keys are bound", InputMap.has_action("aim_up") and InputMap.has_action("attack_key"))
	Input.action_press("aim_up")
	kp._update_aim()
	ok("an aim key points the swing", kp.aim.is_equal_approx(Vector2.UP))
	ok("...and takes the aim off the mouse", not kp.aiming_with_mouse())
	kp._read_input(0.016)
	ok("...and is a swing by itself", kp.state == Player.State.ATTACK)
	Input.action_release("aim_up")

	kp.state = Player.State.IDLE
	kp._cooldowns[kp.slot] = 0.0
	Input.action_press("move_left")
	Input.action_press("attack_key")
	Input.action_press("attack")
	kp._update_aim()
	ok("F swings the way you are walking", kp.aim.is_equal_approx(Vector2.LEFT))
	kp._read_input(0.016)
	ok("...and that is a swing too", kp.state == Player.State.ATTACK)
	Input.action_release("move_left")
	Input.action_release("attack_key")
	Input.action_release("attack")

	kp.state = Player.State.IDLE
	kp._update_aim()
	var first_slot := kp.slot
	Input.action_press("cycle_weapon")
	kp._read_input(0.016)
	Input.action_release("cycle_weapon")
	ok("tab moves along the weapon slots", kp.slot != first_slot)
	kp.queue_free()

	print("\nevery room builds")
	for i in RoomsData.count():
		var room_node := Node2D.new()
		stage.add_child(room_node)
		var info := RoomBuilder.build(room_node, RoomsData.get_room(i))
		var room: Dictionary = RoomsData.get_room(i)
		var have_all := true
		for s in range(1, room.spawns.size() + 1):
			if not info.spawn_points.has(s):
				have_all = false
		ok("%s has a start, a door and %d spawn points" % [room.name, room.spawns.size()],
			info.player_start != Vector2.ZERO and info.door != Vector2.ZERO and have_all)
		room_node.queue_free()

	print("")
	print("all checks passed" if failures == 0 else "%d CHECK(S) FAILED" % failures)
	get_tree().quit(1 if failures > 0 else 0)
