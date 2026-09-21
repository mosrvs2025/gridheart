class_name Enemy
extends CharacterBody2D
## Enemies behave like ordinary action-game enemies - they chase, telegraph,
## swing, keep their distance. The health grid rides above them and changes
## how they should be fought, not how they act.

signal defeated(enemy: Enemy)

enum State { IDLE, CHASE, WINDUP, STRIKE, RECOVER, HURT, DEAD }

var id := "slime"
var data: Dictionary = {}
var grid: HealthGrid
var attack: WeaponData
var state := State.IDLE
var player: Node2D
var knockback := Vector2.ZERO
var hitstop := 0.0

var _timer := 0.0
var _face := 1.0
var _hop := 0.0
var _wander := Vector2.ZERO
var _wander_t := 0.0
var _grid_view: HealthGridView
var _sprite: AnimatedSprite2D
var _shadow: Sprite2D
var _aggro_range := 400.0


static func create(enemy_id: String) -> Enemy:
	var d := EnemyData.get_data(enemy_id)
	var script_path := "res://scripts/enemies/boss.gd" if d.get("boss", false) \
		else "res://scripts/enemies/enemy_base.gd"
	var e: Enemy = load(script_path).new()
	e.id = enemy_id
	e.data = d
	return e


func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 4
	collision_mask = 1
	if data.is_empty():
		data = EnemyData.get_data(id)
	grid = HealthGrid.from_ascii(data.grid)
	grid.emptied.connect(_on_emptied)
	attack = Weapons.enemy_attack(data.attack)

	_shadow = Sprite2D.new()
	_shadow.texture = Art.tex("shadow")
	_shadow.position = Vector2(0, 9 if not data.get("boss", false) else 20)
	_shadow.modulate = Color(1, 1, 1, 0.32)
	if data.get("boss", false):
		_shadow.scale = Vector2(2.0, 1.6)
	_shadow.z_index = -1
	add_child(_shadow)

	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = Art.frames_for(data.sprite)
	_sprite.animation = "idle"
	_sprite.position = Vector2(0, -3 if not data.get("boss", false) else -8)
	_sprite.play()
	add_child(_sprite)

	var shape := CollisionShape2D.new()
	var cap := CapsuleShape2D.new()
	cap.radius = data.radius * 0.6
	cap.height = data.radius * 1.4
	shape.shape = cap
	shape.position = Vector2(0, 2)
	add_child(shape)

	_grid_view = HealthGridView.new()
	_grid_view.setup(grid, 12 if data.get("boss", false) else 6, false)
	_grid_view.position = Vector2(0, grid_view_height())
	_grid_view.z_index = 25
	if data.get("boss", false):
		# the boss's grid is shown in the HUD instead, where it has room
		_grid_view.visible = false
	add_child(_grid_view)
	player = get_tree().get_first_node_in_group("player")
	_on_ready_extra()


func _on_ready_extra() -> void:
	pass


func grid_view_height() -> float:
	return -22.0 - grid.used_rect().size.y * 3.0


func body_radius() -> float:
	return data.radius


func is_alive() -> bool:
	return state != State.DEAD


func _physics_process(delta: float) -> void:
	if hitstop > 0.0:
		hitstop -= delta
		return
	grid.tick(delta)
	if state == State.DEAD:
		knockback = knockback.move_toward(Vector2.ZERO, 900.0 * delta)
		velocity = knockback
		move_and_slide()
		return
	if player == null or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
	_think(delta)
	knockback = knockback.move_toward(Vector2.ZERO, 900.0 * delta)
	velocity += knockback
	move_and_slide()
	_animate(delta)


func _think(delta: float) -> void:
	_timer -= delta
	var to_player := Vector2.ZERO
	var dist := 9999.0
	if player != null and player.alive():
		to_player = player.global_position - global_position
		dist = to_player.length()
	match state:
		State.IDLE:
			velocity = velocity.move_toward(_patrol(delta) * data.speed * 0.4, 400.0 * delta)
			if dist < _aggro_range:
				state = State.CHASE
		State.CHASE:
			_chase(delta, to_player, dist)
		State.WINDUP:
			velocity = velocity.move_toward(Vector2.ZERO, 500.0 * delta)
			if _timer <= 0.0:
				_strike(to_player)
		State.STRIKE:
			if _timer <= 0.0:
				state = State.RECOVER
				_timer = data.recover
		State.RECOVER:
			velocity = velocity.move_toward(Vector2.ZERO, 420.0 * delta)
			if _timer <= 0.0:
				state = State.CHASE
		State.HURT:
			velocity = velocity.move_toward(Vector2.ZERO, 300.0 * delta)
			if _timer <= 0.0:
				state = State.CHASE


func _patrol(delta: float) -> Vector2:
	_wander_t -= delta
	if _wander_t <= 0.0:
		_wander_t = randf_range(0.8, 2.0)
		_wander = Vector2.RIGHT.rotated(randf_range(0.0, TAU)) if randf() < 0.6 else Vector2.ZERO
	return _wander


func _chase(delta: float, to_player: Vector2, dist: float) -> void:
	if player == null or not player.alive():
		velocity = velocity.move_toward(Vector2.ZERO, 400.0 * delta)
		return
	var dir := to_player.normalized()
	var want: Vector2 = dir * data.speed
	if data.get("ranged", false):
		var keep: float = data.keep_distance
		if dist < keep - 12.0:
			want = -dir * data.speed
		elif dist < keep + 12.0:
			want = dir.orthogonal() * data.speed * 0.7 * (1.0 if int(get_instance_id()) % 2 else -1.0)
	if data.get("hop", false):
		_hop -= delta
		if _hop <= 0.0:
			_hop = 0.85
		want *= 1.6 if _hop > 0.45 else 0.15
	velocity = velocity.move_toward(want + _avoid() * 40.0, 500.0 * delta)
	if dist <= data.attack_range and _timer <= 0.0:
		state = State.WINDUP
		_timer = data.windup
		_on_windup()


func _avoid() -> Vector2:
	var push := Vector2.ZERO
	for e in get_tree().get_nodes_in_group("enemies"):
		if e == self or not is_instance_valid(e):
			continue
		var d: Vector2 = global_position - e.global_position
		var l := d.length()
		if l < 16.0 and l > 0.1:
			push += d / l * (16.0 - l) * 0.5
	return push


func _on_windup() -> void:
	_sprite.animation = "attack"
	_sprite.frame = 0
	_sprite.play()


func _strike(to_player: Vector2) -> void:
	state = State.STRIKE
	_timer = 0.16
	if player == null or not player.alive():
		return
	var dir := to_player.normalized()
	if data.get("ranged", false):
		var p := Projectile.create("arrow", dir, 150.0, attack, self)
		p.global_position = global_position + dir * 8.0 + Vector2(0, -4)
		get_parent().add_child(p)
		Sfx.play("shoot", -15.0)
		return
	Sfx.play("swing_heavy" if data.get("heavy", false) else "swing_light", -16.0)
	if data.get("contact", false):
		velocity = dir * 190.0
	if to_player.length() <= data.attack_range + 10.0:
		Fx.swing(get_parent(), global_position + Vector2(0, -3), dir.angle(),
			"fx_slash", 0.16, dir.x < 0.0, Color(1, 0.8, 0.75))
		player.take_hit(attack, dir, global_position, self)


## A successful world-space hit; the resolver turns it into grid damage.
func take_hit(w: WeaponData, dir: Vector2, from: Vector2, _source) -> void:
	if state == State.DEAD:
		return
	var local := from - global_position
	var res := CombatResolver.resolve(grid, w, dir, local, body_radius() * 1.2)
	_grid_view.pulse(1.0)
	knockback = dir.normalized() * w.knockback
	hitstop = w.hitstop
	state = State.HURT
	_timer = 0.16 if not data.get("heavy", false) else 0.1
	_sprite.animation = "hurt"
	_sprite.frame = 0
	var centre := global_position + Vector2(0, -4)
	if not res.blocked.is_empty() and res.destroyed.is_empty() and res.hit.is_empty():
		Sfx.play("armor_clang", -8.0)
		Fx.sparks(get_parent(), centre, -dir, 6, Color(0.85, 0.9, 1.0), 120.0)
	elif not res.pierced.is_empty():
		Sfx.play("pierce", -10.0)
	if not res.chipped.is_empty():
		Sfx.play("armor_clang", -10.0)
		Fx.shards(get_parent(), centre, res.chipped.size(), Color(0.82, 0.86, 0.95))
	if not res.poisoned.is_empty():
		Sfx.play("poison_tick", -14.0)
		Fx.sparks(get_parent(), centre, -dir, 3, Color(0.55, 0.85, 0.42), 50.0)
	if not res.destroyed.is_empty():
		Sfx.play("cell_break", -8.0)
		Fx.shards(get_parent(), centre, mini(res.destroyed.size(), 5))
	elif not res.hit.is_empty():
		Sfx.play("hit_cell", -12.0)
		Fx.sparks(get_parent(), centre, -dir, 3)
	if res.missed > 0 and res.destroyed.is_empty() and res.hit.is_empty() and res.blocked.is_empty():
		Fx.popup(get_parent(), centre + Vector2(0, -10), "whiff", Color(0.85, 0.8, 0.78))


func _on_emptied() -> void:
	if state == State.DEAD:
		return
	state = State.DEAD
	collision_layer = 0
	_sprite.animation = "death"
	_sprite.frame = 0
	_sprite.play()
	_grid_view.visible = false
	Sfx.play("boss_die" if data.get("boss", false) else "enemy_die", -8.0)
	Fx.shards(get_parent(), global_position + Vector2(0, -6), 7)
	Game.shake(2.0 if not data.get("boss", false) else 6.0)
	defeated.emit(self)
	var tw := create_tween()
	tw.tween_interval(0.7)
	tw.tween_property(self, "modulate:a", 0.0, 0.3)
	tw.tween_callback(queue_free)


func _animate(_delta: float) -> void:
	if player != null and is_instance_valid(player):
		_face = signf(player.global_position.x - global_position.x)
	if _face != 0.0:
		_sprite.flip_h = _face < 0.0
	match state:
		State.WINDUP:
			var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.03)
			_sprite.modulate = Color(1, 1, 1).lerp(Color(1.6, 1.2, 1.0), pulse)
			_sprite.scale = Vector2(1.0 + pulse * 0.08, 1.0 - pulse * 0.06)
		State.HURT:
			_sprite.modulate = Color(2.2, 1.6, 1.6)
			_sprite.scale = Vector2(1.12, 0.9)
		State.DEAD:
			_sprite.modulate = Color(1, 1, 1)
		_:
			_sprite.modulate = _sprite.modulate.lerp(Color(1, 1, 1), 0.25)
			_sprite.scale = _sprite.scale.lerp(Vector2.ONE, 0.25)
			if state == State.CHASE and velocity.length() > 8.0:
				if _sprite.animation != "run":
					_sprite.animation = "run"
					_sprite.play()
			elif state == State.IDLE or state == State.RECOVER:
				if _sprite.animation != "idle":
					_sprite.animation = "idle"
					_sprite.play()
	_grid_view.position = Vector2(0, grid_view_height())
