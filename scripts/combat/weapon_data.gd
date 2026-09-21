class_name WeaponData
extends Resource
## A weapon is two things at once: a swing in the world, and a shape that
## bites into the target's health grid.

enum Kind { SWING, THRUST, SLAM, SHOOT }

@export var id: String = "sword"
@export var display_name: String = "Sword"
@export var blurb: String = ""

## Offsets for an attack aimed to the right. Rotated to match the real
## attack direction at resolve time.
@export var pattern: Array = [Vector2i(0, 0)]

@export var damage: int = 1
@export var penetration: int = 2
@export var armor_break: int = 1
@export var poison: int = 0

@export var kind: int = Kind.SWING
@export var cooldown: float = 0.42
@export var windup: float = 0.08
@export var reach: float = 34.0
@export var arc_deg: float = 110.0
@export var knockback: float = 95.0
@export var shake: float = 1.0
@export var hitstop: float = 0.045
@export var max_targets: int = 3
@export var icon_name: String = "icon_sword"
@export var fx: String = "fx_slash"
@export var sfx: String = "swing_light"


func pattern_size() -> Vector2i:
	var mx := Vector2i.ZERO
	for p in pattern:
		mx = mx.max(p)
	return mx + Vector2i.ONE


## The pattern as ASCII, for menus that want to show the shape.
func pattern_rows() -> Array:
	var size := pattern_size()
	var rows := []
	for y in size.y:
		var line := ""
		for x in size.x:
			line += "#" if pattern.has(Vector2i(x, y)) else "."
		rows.append(line)
	return rows
