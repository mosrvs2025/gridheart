class_name Projectile
extends Area2D
## Arrows and hollow orbs. Where the shot lands on the target decides which
## cell it takes, so aiming matters at range too.

var dir := Vector2.RIGHT
var speed := 200.0
var weapon: WeaponData
var source: Node2D
var from_player := false
var life := 2.6
var spin := false


static func create(art: String, direction: Vector2, spd: float, w: WeaponData,
		src: Node2D) -> Projectile:
	var p := Projectile.new()
	p.set_script(load("res://scenes/weapons/projectile.gd"))
	p.dir = direction.normalized()
	p.speed = spd
	p.weapon = w
	p.source = src
	p.from_player = src != null and src.is_in_group("player")
	var s := Sprite2D.new()
	s.name = "Sprite"
	if art == "orb":
		var a := AnimatedSprite2D.new()
		a.name = "Sprite"
		var sf := SpriteFrames.new()
		sf.set_animation_speed("default", 8.0)
		for t in Art.slice_n("orb", 2):
			sf.add_frame("default", t)
		a.sprite_frames = sf
		a.play()
		p.add_child(a)
		p.spin = false
	else:
		s.texture = Art.slice_n("arrow", 1)[0]
		s.rotation = p.dir.angle()
		p.add_child(s)
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 4.0
	shape.shape = circle
	p.add_child(shape)
	p.z_index = 5
	return p


func _ready() -> void:
	monitoring = true
	collision_layer = 16
	collision_mask = 0
	add_to_group("projectiles")


func _physics_process(delta: float) -> void:
	position += dir * speed * delta
	life -= delta
	if life <= 0.0:
		queue_free()
		return
	var space := get_world_2d().direct_space_state
	var q := PhysicsRayQueryParameters2D.create(global_position - dir * 4.0, global_position)
	q.collision_mask = 1
	if not space.intersect_ray(q).is_empty():
		_burst()
		return
	if from_player:
		for e in get_tree().get_nodes_in_group("enemies"):
			if is_instance_valid(e) and e.is_alive() \
					and global_position.distance_to(e.global_position) < e.body_radius() + 4.0:
				e.take_hit(weapon, dir, global_position, source)
				_burst()
				return
	else:
		var p := get_tree().get_first_node_in_group("player")
		if p != null and p.alive() and global_position.distance_to(p.global_position) < 10.0:
			p.take_hit(weapon, dir, global_position, source)
			_burst()


func _burst() -> void:
	Sfx.play("arrow_hit", -16.0)
	Fx.sparks(get_parent(), global_position, -dir, 3, Color(1, 0.95, 0.85), 60.0)
	queue_free()
