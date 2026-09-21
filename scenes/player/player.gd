class_name Player
extends CharacterBody2D
## The player: ordinary responsive top-down action movement, three weapon
## slots, and a health grid that lives in the HUD rather than on the body.

signal grid_changed
signal died
signal weapon_switched(slot: int)

const SPEED := 108.0
const ACCEL := 1100.0
const FRICTION := 1400.0
const DODGE_SPEED := 265.0
const DODGE_TIME := 0.20
const DODGE_COOLDOWN := 0.46
const DODGE_IFRAMES := 0.30
const HIT_IFRAMES := 0.85
const GRID_CANVAS := 11

enum State { IDLE, RUN, ATTACK, DODGE, HURT, DEAD }

var grid: HealthGrid
var slots: Array[WeaponData] = []
var slot := 0
var state := State.IDLE
var aim := Vector2.RIGHT
var invuln := 0.0
var hitstop := 0.0
var god_mode := false

var _state_timer := 0.0
var _cooldowns := [0.0, 0.0, 0.0]
var _dodge_cd := 0.0
var _dodge_dir := Vector2.RIGHT
var _pending_attack := false
var _attack_dir := Vector2.RIGHT
var _trail := 0.0

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var shadow: Sprite2D = $Shadow


func _ready() -> void:
	add_to_group("player")
	collision_layer = 2
	collision_mask = 1
	grid = HealthGrid.seeded(GRID_CANVAS, 3, 2)
	grid.changed.connect(func(): grid_changed.emit())
	grid.emptied.connect(_on_emptied)
	grid.cells_destroyed.connect(func(c): Run.cells_lost += c.size())
	for id in Weapons.STARTING:
		slots.append(Weapons.make(id))


static func create() -> Player:
	var p := Player.new()
	p.set_script(load("res://scenes/player/player.gd"))
	var shadow := Sprite2D.new()
	shadow.name = "Shadow"
	shadow.texture = Art.tex("shadow")
	shadow.position = Vector2(0, 9)
	shadow.modulate = Color(1, 1, 1, 0.34)
	shadow.z_index = -1
	p.add_child(shadow)
	var spr := AnimatedSprite2D.new()
	spr.name = "Sprite"
	spr.sprite_frames = Art.frames_for("player")
	spr.animation = "idle"
	spr.position = Vector2(0, -3)
	p.add_child(spr)
	var shape := CollisionShape2D.new()
	var cap := CapsuleShape2D.new()
	cap.radius = 5.0
	cap.height = 12.0
	shape.shape = cap
	shape.position = Vector2(0, 3)
	p.add_child(shape)
	return p


func weapon() -> WeaponData:
	return slots[slot]


func cooldown_ratio(index: int) -> float:
	if index < 0 or index >= slots.size():
		return 0.0
	return clampf(_cooldowns[index] / maxf(slots[index].cooldown, 0.01), 0.0, 1.0)


func aim_offset() -> Vector2:
	return aim * 16.0


func alive() -> bool:
	return state != State.DEAD


func _physics_process(delta: float) -> void:
	if hitstop > 0.0:
		hitstop -= delta
		velocity = Vector2.ZERO
		return
	invuln = maxf(0.0, invuln - delta)
	_dodge_cd = maxf(0.0, _dodge_cd - delta)
	for i in _cooldowns.size():
		_cooldowns[i] = maxf(0.0, _cooldowns[i] - delta)
	grid.tick(delta)

	if state == State.DEAD:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
		move_and_slide()
		return

	_update_aim()
	_read_input(delta)
	_advance_state(delta)
	move_and_slide()
	_animate(delta)


func _update_aim() -> void:
	var m := get_global_mouse_position()
	var d := m - global_position
	if d.length() > 2.0:
		aim = d.normalized()


func _read_input(delta: float) -> void:
	if state == State.DODGE or state == State.HURT:
		return
	for i in 3:
		if Input.is_action_just_pressed("slot_%d" % (i + 1)) and i < slots.size() and slot != i:
			slot = i
			weapon_switched.emit(i)
			Sfx.play("ui_move", -14.0)
	if Input.is_action_just_pressed("dodge") and _dodge_cd <= 0.0:
		_start_dodge()
		return
	if Input.is_action_pressed("attack") and state != State.ATTACK and _cooldowns[slot] <= 0.0:
		_start_attack()
		return
	if state == State.ATTACK:
		return
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if dir.length_squared() > 0.01:
		velocity = velocity.move_toward(dir.normalized() * SPEED, ACCEL * delta)
		state = State.RUN
	else:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
		state = State.IDLE


func _start_dodge() -> void:
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	_dodge_dir = dir.normalized() if dir.length_squared() > 0.01 else aim
	state = State.DODGE
	_state_timer = DODGE_TIME
	_dodge_cd = DODGE_COOLDOWN
	invuln = maxf(invuln, DODGE_IFRAMES)
	velocity = _dodge_dir * DODGE_SPEED
	Sfx.play("dash", -13.0)


func _start_attack() -> void:
	var w := weapon()
	state = State.ATTACK
	_state_timer = w.windup
	_pending_attack = true
	_attack_dir = aim
	_cooldowns[slot] = w.cooldown
	velocity *= 0.35
	sprite.animation = "attack"
	sprite.frame = 0
	sprite.play()
	Sfx.play(w.sfx, -11.0)


func _advance_state(delta: float) -> void:
	match state:
		State.DODGE:
			velocity = _dodge_dir * DODGE_SPEED
			_trail -= delta
			if _trail <= 0.0:
				_trail = 0.045
				_spawn_afterimage()
			_state_timer -= delta
			if _state_timer <= 0.0:
				state = State.IDLE
		State.ATTACK:
			velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
			_state_timer -= delta
			if _state_timer <= 0.0 and _pending_attack:
				_pending_attack = false
				_land_attack()
			elif _state_timer <= -0.14:
				state = State.IDLE
		State.HURT:
			velocity = velocity.move_toward(Vector2.ZERO, FRICTION * 0.5 * delta)
			_state_timer -= delta
			if _state_timer <= 0.0:
				state = State.IDLE


func _spawn_afterimage() -> void:
	var s := Sprite2D.new()
	s.texture = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	s.global_position = sprite.global_position
	s.flip_h = sprite.flip_h
	s.modulate = Color(0.75, 0.95, 0.85, 0.5)
	s.z_index = -2
	get_parent().add_child(s)
	var tw := s.create_tween()
	tw.tween_property(s, "modulate:a", 0.0, 0.2)
	tw.tween_callback(s.queue_free)


## Finds everything the swing actually connects with, then lets the resolver
## decide what that means inside each target's grid.
func _land_attack() -> void:
	var w := weapon()
	var origin := global_position
	if w.kind == WeaponData.Kind.SHOOT:
		_shoot(w)
		return
	Fx.swing(get_parent(), origin + Vector2(0, -3), _attack_dir.angle(), w.fx, 0.16,
		_attack_dir.x < 0.0)
	var hits := 0
	for e in get_tree().get_nodes_in_group("enemies"):
		if hits >= w.max_targets or not is_instance_valid(e) or not e.is_alive():
			continue
		var to: Vector2 = e.global_position - origin
		var dist: float = to.length() - e.body_radius()
		if dist > w.reach:
			continue
		if w.arc_deg < 360.0 and absf(rad_to_deg(_attack_dir.angle_to(to))) > w.arc_deg * 0.5:
			continue
		hits += 1
		e.take_hit(w, _attack_dir, origin, self)
	if hits > 0:
		hitstop = w.hitstop
		Game.shake(w.shake)
	else:
		Fx.sparks(get_parent(), origin + _attack_dir * w.reach * 0.6, _attack_dir, 2,
			Color(1, 1, 1, 0.4), 40.0)


func _shoot(w: WeaponData) -> void:
	var p := Projectile.create("arrow", _attack_dir, 210.0, w, self)
	p.global_position = global_position + _attack_dir * 10.0 + Vector2(0, -3)
	get_parent().add_child(p)


## Incoming damage runs through the same resolver the player's weapons do.
func take_hit(w: WeaponData, dir: Vector2, from: Vector2, _source) -> void:
	if invuln > 0.0 or state == State.DEAD or god_mode:
		return
	var local := from - global_position
	var res := CombatResolver.resolve(grid, w, dir, local, 11.0)
	invuln = HIT_IFRAMES
	state = State.HURT
	_state_timer = 0.22
	velocity = dir.normalized() * 140.0
	Sfx.play("hurt", -6.0)
	Game.shake(2.4)
	hitstop = 0.06
	Fx.sparks(get_parent(), global_position + Vector2(0, -4), -dir, 5, Color(1, 0.6, 0.6))
	if not res.destroyed.is_empty():
		Fx.shards(get_parent(), global_position + Vector2(0, -6), res.destroyed.size(),
			Color(1, 0.82, 0.72))
	grid_changed.emit()


func heal_shape(shape: Array, origin: Vector2i) -> void:
	grid.heal(shape, origin)
	Sfx.play("heal", -6.0)
	grid_changed.emit()


func attach_growth(shape: Array, origin: Vector2i) -> void:
	grid.attach(shape, origin)
	Sfx.play("place", -6.0)
	grid_changed.emit()


func give_weapon(w: WeaponData, into_slot: int) -> void:
	if into_slot >= 0 and into_slot < slots.size():
		slots[into_slot] = w
		slot = into_slot
		weapon_switched.emit(into_slot)


func _on_emptied() -> void:
	if state == State.DEAD:
		return
	state = State.DEAD
	velocity = Vector2.ZERO
	sprite.animation = "death"
	sprite.frame = 0
	sprite.play()
	Sfx.play("enemy_die", -4.0)
	died.emit()


func _animate(delta: float) -> void:
	if aim.x != 0.0:
		sprite.flip_h = aim.x < 0.0
	sprite.modulate = Color(1, 1, 1)
	if invuln > 0.0 and state != State.DEAD:
		var blink := fmod(invuln, 0.16) < 0.08
		sprite.modulate = Color(1, 0.7, 0.7, 0.55) if blink else Color(1, 1, 1)
	match state:
		State.ATTACK:
			if sprite.animation != "attack":
				sprite.animation = "attack"
				sprite.play()
		State.HURT:
			if sprite.animation != "hurt":
				sprite.animation = "hurt"
				sprite.play()
		State.DODGE:
			sprite.animation = "run"
			sprite.play()
		State.RUN:
			if sprite.animation != "run":
				sprite.animation = "run"
				sprite.play()
		State.IDLE:
			if sprite.animation != "idle":
				sprite.animation = "idle"
				sprite.play()
	shadow.modulate.a = 0.34 if state != State.DODGE else 0.18
