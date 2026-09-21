class_name HealthCell
extends RefCounted
## One square of a combatant's health. Pure data - nothing here knows how it
## is drawn.

enum Kind { NORMAL, ARMORED }

var kind: int = Kind.NORMAL
var hp: int = 1
var max_hp: int = 1
var armor: int = 0
var max_armor: int = 0
var poison: int = 0          ## remaining poison stacks; 0 means clean
var alive: bool = true


func _init(cell_kind: int = Kind.NORMAL, cell_hp: int = 1, cell_armor: int = 0) -> void:
	kind = cell_kind
	hp = cell_hp
	max_hp = cell_hp
	armor = cell_armor
	max_armor = cell_armor


func is_armored() -> bool:
	return armor > 0


func is_chipped() -> bool:
	return max_armor > 0 and armor <= 0


func is_wounded() -> bool:
	return alive and hp < max_hp


func duplicate_cell() -> HealthCell:
	var c := HealthCell.new(kind, max_hp, max_armor)
	c.hp = hp
	c.armor = armor
	c.poison = poison
	c.alive = alive
	return c
