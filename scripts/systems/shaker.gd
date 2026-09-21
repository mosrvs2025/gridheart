class_name Shaker
extends Camera2D
## Camera that follows a target and shakes, gently, only when it matters.

var target: Node2D
var follow_speed := 6.5
var _trauma := 0.0
var _look := Vector2.ZERO


func _ready() -> void:
	position_smoothing_enabled = false


func add_trauma(amount: float) -> void:
	_trauma = minf(1.0, _trauma + amount * 0.14)


func _process(delta: float) -> void:
	if target != null and is_instance_valid(target):
		var aim := target.global_position
		if target.has_method("aim_offset"):
			aim += target.aim_offset()
		_look = _look.lerp(aim, clampf(delta * follow_speed, 0.0, 1.0))
		global_position = _look.round()
	if _trauma > 0.0:
		_trauma = maxf(0.0, _trauma - delta * 2.4)
		var s := _trauma * _trauma * 5.0
		offset = Vector2(randf_range(-s, s), randf_range(-s, s)).round()
	elif offset != Vector2.ZERO:
		offset = Vector2.ZERO


func snap_to(pos: Vector2) -> void:
	_look = pos
	global_position = pos.round()
