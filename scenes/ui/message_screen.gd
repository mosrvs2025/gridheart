class_name MessageScreen
extends Control
## Title, defeat and victory. One key, one message, no menus to get lost in.

signal dismissed

var heading := ""
var body := ""
var footer := "click to begin"
var accent := Ui.GOLD
var show_logo := false


static func create(heading: String, body: String, footer: String,
		accent := Ui.GOLD, logo := false) -> MessageScreen:
	var s := MessageScreen.new()
	s.set_script(load("res://scenes/ui/message_screen.gd"))
	s.heading = heading
	s.body = body
	s.footer = footer
	s.accent = accent
	s.show_logo = logo
	return s


func _ready() -> void:
	position = Vector2.ZERO
	size = Ui.SCREEN
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(Ui.dim_layer(0.82))
	var h := Ui.title(heading, 16 if not show_logo else 24, accent)
	h.size = Vector2(480, 30)
	h.position = Vector2(0, 62 if show_logo else 76)
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(h)
	var lines := body.split("\n")
	for i in lines.size():
		var l := Ui.label(lines[i], 8, Ui.INK if i == 0 else Ui.DIM)
		l.size = Vector2(480, 12)
		l.position = Vector2(0, 118 + i * 13)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(l)
	var f := Ui.label(footer, 8, accent)
	f.size = Vector2(480, 12)
	f.position = Vector2(0, 224)
	f.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(f)
	var tw := create_tween().set_loops()
	tw.tween_property(f, "modulate:a", 0.25, 0.7)
	tw.tween_property(f, "modulate:a", 1.0, 0.7)


func _unhandled_input(event: InputEvent) -> void:
	var go := Input.is_action_just_pressed("confirm") or Input.is_action_just_pressed("dodge")
	if (event is InputEventMouseButton and event.pressed) or go:
		Sfx.play("ui_confirm", -8.0)
		dismissed.emit()
		queue_free()
