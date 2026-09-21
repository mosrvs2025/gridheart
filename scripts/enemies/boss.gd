class_name Boss
extends Enemy
## The Hollow Sovereign. Its grid is the fight: armoured pauldrons on the
## flanks, a doubly-plated core in the middle, and a soft underside. Break the
## flanks and it changes how it moves; break the core and it starts to come
## apart.

const FLANKS := [Vector2i(0, 0), Vector2i(1, 0), Vector2i(6, 0), Vector2i(7, 0),
	Vector2i(0, 1), Vector2i(7, 1)]
const CORE := [Vector2i(3, 2), Vector2i(4, 2)]

var phase := 1
var _cycle := 0
var _orb_attack: WeaponData
var _charging := false
var _charge_dir := Vector2.RIGHT


func _on_ready_extra() -> void:
	_orb_attack = Weapons.enemy_attack("boss_orb")
	_aggro_range = 9999.0
	_grid_view.idle_alpha = 1.0


func grid_view_height() -> float:
	return -46.0


func _think(delta: float) -> void:
	_update_phase()
	if _charging:
		velocity = _charge_dir * 240.0
		_timer -= delta
		if _timer <= 0.0 or get_slide_collision_count() > 0:
			_charging = false
			state = State.RECOVER
			_timer = 0.5
			Game.shake(3.0)
		elif player != null and player.alive() \
				and global_position.distance_to(player.global_position) < 26.0:
			player.take_hit(attack, _charge_dir, global_position, self)
		return
	super._think(delta)


func _update_phase() -> void:
	var flanks_gone := true
	for c in FLANKS:
		var cell := grid.get_cell(c)
		if cell != null and cell.alive:
			flanks_gone = false
			break
	var core_gone := true
	for c in CORE:
		var cell := grid.get_cell(c)
		if cell != null and cell.alive:
			core_gone = false
			break
	var want := 1
	if flanks_gone or grid.alive_count() < grid.total_count() * 0.6:
		want = 2
	if core_gone or grid.alive_count() < grid.total_count() * 0.3:
		want = 3
	if want != phase:
		phase = want
		data.speed = [0.0, 44.0, 62.0, 78.0][phase]
		data.windup = [0.0, 0.6, 0.48, 0.36][phase]
		if phase >= 2:
			_sprite.sprite_frames = Art.frames_for("boss")
			_sprite.animation = "broken"
			_sprite.play()
		Game.shake(4.0)
		Sfx.play("boss_hurt", -4.0)
		Fx.popup(get_parent(), global_position + Vector2(0, -56),
			["", "", "the plating gives", "the crown cracks"][phase], Color(1, 0.86, 0.6))


func _strike(to_player: Vector2) -> void:
	state = State.STRIKE
	_timer = 0.2
	if player == null or not player.alive():
		return
	_cycle += 1
	var dir := to_player.normalized()
	# Phase 2 and 3 mix in a volley and a charge, so the fight keeps changing
	# as its grid comes apart.
	if phase >= 2 and _cycle % 3 == 0:
		_volley(dir)
		return
	if phase >= 3 and _cycle % 4 == 0:
		_charging = true
		_charge_dir = dir
		_timer = 0.7
		Sfx.play("swing_heavy", -8.0)
		return
	Sfx.play("swing_heavy", -10.0)
	Fx.swing(get_parent(), global_position + dir * 22.0 + Vector2(0, -8), dir.angle(),
		"fx_slam", 0.22, false, Color(1, 0.85, 0.7))
	Game.shake(2.5)
	if to_player.length() <= data.attack_range + 16.0:
		player.take_hit(attack, dir, global_position, self)


func _volley(dir: Vector2) -> void:
	Sfx.play("shoot", -8.0)
	var spread := 5 if phase >= 3 else 3
	for i in spread:
		var a := dir.rotated(deg_to_rad(-18.0 * (spread - 1) * 0.5 + 18.0 * i))
		var p := Projectile.create("orb", a, 96.0, _orb_attack, self)
		p.global_position = global_position + a * 14.0 + Vector2(0, -8)
		get_parent().add_child(p)
