extends Node
## Registers the input map at runtime so the bindings live in code, next to
## the code that reads them.

const BINDINGS := {
	"move_up": [KEY_W, KEY_UP],
	"move_down": [KEY_S, KEY_DOWN],
	"move_left": [KEY_A, KEY_LEFT],
	"move_right": [KEY_D, KEY_RIGHT],
	"dodge": [KEY_SPACE, KEY_SHIFT],
	"slot_1": [KEY_1],
	"slot_2": [KEY_2],
	"slot_3": [KEY_3],
	"rotate_shape": [KEY_R, KEY_Q],
	"confirm": [KEY_ENTER, KEY_KP_ENTER, KEY_E],
	"restart": [KEY_R],
	"pause": [KEY_ESCAPE, KEY_P],
}


func _ready() -> void:
	for action in BINDINGS:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key in BINDINGS[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event(action, ev)
	_add_mouse("attack", MOUSE_BUTTON_LEFT)
	_add_mouse("alt_action", MOUSE_BUTTON_RIGHT)


func _add_mouse(action: String, button: int) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var ev := InputEventMouseButton.new()
	ev.button_index = button
	InputMap.action_add_event(action, ev)
