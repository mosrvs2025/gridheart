class_name Fx
extends RefCounted
## Small, pooled-enough visual effects. Kept deliberately cheap: a handful of
## sprites per hit, no shaders, nothing the browser will choke on.


static func sparks(parent: Node, pos: Vector2, dir: Vector2, count := 5,
		color := Color(1, 1, 1), speed := 90.0) -> void:
	var tex := Art.tex("spark")
	if tex == null:
		return
	for i in count:
		var s := Sprite2D.new()
		s.texture = tex
		s.position = pos
		s.modulate = color
		s.z_index = 40
		parent.add_child(s)
		var a := dir.angle() + randf_range(-0.9, 0.9)
		var v := Vector2(cos(a), sin(a)) * speed * randf_range(0.5, 1.4)
		var tw := s.create_tween()
		tw.set_parallel(true)
		tw.tween_property(s, "position", pos + v * 0.28, 0.28)
		tw.tween_property(s, "scale", Vector2(0.2, 0.2), 0.28)
		tw.tween_property(s, "modulate:a", 0.0, 0.28)
		tw.chain().tween_callback(s.queue_free)


static func shards(parent: Node, pos: Vector2, count := 4, color := Color(1, 0.94, 0.8)) -> void:
	var tex := Art.tex("shard")
	if tex == null:
		return
	for i in count:
		var s := Sprite2D.new()
		s.texture = tex
		s.position = pos + Vector2(randf_range(-3, 3), randf_range(-3, 3))
		s.modulate = color
		s.z_index = 41
		parent.add_child(s)
		var v := Vector2(randf_range(-1, 1), randf_range(-1.4, -0.3)).normalized() * randf_range(40, 110)
		var tw := s.create_tween()
		tw.set_parallel(true)
		tw.tween_property(s, "position", s.position + v * 0.42 + Vector2(0, 26), 0.42)
		tw.tween_property(s, "rotation", randf_range(-4, 4), 0.42)
		tw.tween_property(s, "modulate:a", 0.0, 0.42).set_delay(0.18)
		tw.chain().tween_callback(s.queue_free)


## Where each effect strip's own origin sits, so a swing pivots on the hand
## rather than on the middle of its texture.
const PIVOTS := {"fx_slash": Vector2(14, 0), "fx_thrust": Vector2(16, 0), "fx_slam": Vector2.ZERO}


## A one-shot animated sprite for swings and slams.
static func swing(parent: Node, pos: Vector2, angle: float, strip: String,
		duration := 0.18, flip_v := false, color := Color(1, 1, 1)) -> void:
	if strip == "":
		return
	var frames := Art.slice_n(strip, 3)
	if frames.is_empty():
		return
	var s := Sprite2D.new()
	s.texture = frames[0]
	s.position = pos
	s.offset = PIVOTS.get(strip, Vector2.ZERO)
	s.rotation = angle
	s.flip_v = flip_v
	s.modulate = color
	s.z_index = 35
	parent.add_child(s)
	var step := duration / frames.size()
	var tw := s.create_tween()
	for i in range(1, frames.size()):
		tw.tween_interval(step)
		tw.tween_callback(func(): s.texture = frames[i])
	tw.tween_interval(step)
	tw.tween_property(s, "modulate:a", 0.0, step)
	tw.tween_callback(s.queue_free)


static func popup(parent: Node, pos: Vector2, text: String, color := Color(1, 1, 1)) -> void:
	var l := Label.new()
	l.text = text
	l.position = pos - Vector2(40, 8)
	l.size = Vector2(80, 12)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 8)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0.12, 0.09, 0.15))
	l.add_theme_constant_override("outline_size", 3)
	l.z_index = 60
	parent.add_child(l)
	var tw := l.create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "position:y", l.position.y - 14, 0.7)
	tw.tween_property(l, "modulate:a", 0.0, 0.7).set_delay(0.3)
	tw.chain().tween_callback(l.queue_free)
