extends Node
## Registers the input map at runtime so the bindings live in code, next to
## the code that reads them.
##
## The game is playable two ways, and neither is a fallback for the other:
## mouse aim with a click to swing, or the right hand on the arrow keys, where
## a direction key aims and swings in one press.

const BINDINGS := {
	"move_up": [KEY_W],
	"move_down": [KEY_S],
	"move_left": [KEY_A],
	"move_right": [KEY_D],
	# a direction key is an attack: it turns the swing and throws it
	"aim_up": [KEY_UP, KEY_I],
	"aim_down": [KEY_DOWN, KEY_K],
	"aim_left": [KEY_LEFT, KEY_J],
	"aim_right": [KEY_RIGHT, KEY_L],
	# swing where you are already facing, for a hand that never leaves WASD
	"attack_key": [KEY_F],
	"dodge": [KEY_SPACE, KEY_SHIFT],
	"slot_1": [KEY_1],
	"slot_2": [KEY_2],
	"slot_3": [KEY_3],
	"cycle_weapon": [KEY_TAB, KEY_Q],
	"rotate_shape": [KEY_R],
	"confirm": [KEY_ENTER, KEY_KP_ENTER, KEY_E, KEY_SPACE],
	"restart": [KEY_R],
	"pause": [KEY_ESCAPE, KEY_P],
}

## Keys that steer a cursor on the between-rooms screens, where WASD and the
## arrows mean the same thing because nothing is being aimed at.
const CURSOR := {
	"cursor_up": [KEY_W, KEY_UP, KEY_I],
	"cursor_down": [KEY_S, KEY_DOWN, KEY_K],
	"cursor_left": [KEY_A, KEY_LEFT, KEY_J],
	"cursor_right": [KEY_D, KEY_RIGHT, KEY_L],
}


func _ready() -> void:
	for action in BINDINGS:
		_bind(action, BINDINGS[action])
	for action in CURSOR:
		_bind(action, CURSOR[action])
	_add_mouse("attack", MOUSE_BUTTON_LEFT)
	_add_mouse("alt_action", MOUSE_BUTTON_RIGHT)
	# the keyboard swing key lives in the same action as the mouse button, so
	# everything downstream only has to ask whether "attack" is held
	_bind("attack", [KEY_F])


func _bind(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for key in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = key
		InputMap.action_add_event(action, ev)


func _add_mouse(action: String, button: int) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var ev := InputEventMouseButton.new()
	ev.button_index = button
	InputMap.action_add_event(action, ev)
