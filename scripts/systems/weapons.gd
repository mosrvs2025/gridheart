class_name Weapons
extends RefCounted
## The weapon roster. Each entry pairs a world-space attack with the shape it
## carves out of a health grid - weapons differ by geometry first and numbers
## second.

const SWORD := "sword"
const SPEAR := "spear"
const HAMMER := "hammer"
const AXE := "axe"
const DAGGER := "dagger"
const BOW := "bow"

const STARTING := [SWORD, SPEAR, HAMMER]
const UNLOCKABLE := [AXE, DAGGER, BOW]


static func make(id: String) -> WeaponData:
	var w := WeaponData.new()
	w.id = id
	match id:
		SWORD:
			w.display_name = "Sword"
			w.blurb = "A wide slash. Four cells in a row, along the swing."
			w.pattern = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)]
			w.damage = 1
			w.penetration = 2
			w.armor_break = 1
			w.kind = WeaponData.Kind.SWING
			w.cooldown = 0.40
			w.windup = 0.07
			w.reach = 34.0
			w.arc_deg = 115.0
			w.knockback = 95.0
			w.shake = 1.2
			w.max_targets = 3
			w.icon_name = "icon_sword"
			w.fx = "fx_slash"
			w.sfx = "swing_light"
		SPEAR:
			w.display_name = "Spear"
			w.blurb = "A long thrust. Bites a column across the grain of the swing."
			w.pattern = [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(0, 3)]
			w.damage = 1
			w.penetration = 3
			w.armor_break = 1
			w.kind = WeaponData.Kind.THRUST
			w.cooldown = 0.55
			w.windup = 0.12
			w.reach = 52.0
			w.arc_deg = 34.0
			w.knockback = 70.0
			w.shake = 1.0
			w.max_targets = 2
			w.icon_name = "icon_spear"
			w.fx = "fx_thrust"
			w.sfx = "thrust"
		HAMMER:
			w.display_name = "Hammer"
			w.blurb = "A heavy slam. A 2x2 block, and plate gives way under it."
			w.pattern = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]
			w.damage = 1
			w.penetration = 1
			w.armor_break = 3
			w.kind = WeaponData.Kind.SLAM
			w.cooldown = 0.78
			w.windup = 0.22
			w.reach = 30.0
			w.arc_deg = 360.0
			w.knockback = 180.0
			w.shake = 3.0
			w.hitstop = 0.09
			w.max_targets = 4
			w.icon_name = "icon_hammer"
			w.fx = "fx_slam"
			w.sfx = "swing_heavy"
		AXE:
			w.display_name = "Axe"
			w.blurb = "A hooked chop. An awkward chunk that takes odd corners off."
			w.pattern = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2)]
			w.damage = 1
			w.penetration = 2
			w.armor_break = 2
			w.kind = WeaponData.Kind.SWING
			w.cooldown = 0.62
			w.windup = 0.16
			w.reach = 36.0
			w.arc_deg = 130.0
			w.knockback = 140.0
			w.shake = 2.0
			w.hitstop = 0.07
			w.max_targets = 3
			w.icon_name = "icon_axe"
			w.fx = "fx_slash"
			w.sfx = "swing_heavy"
		DAGGER:
			w.display_name = "Dagger"
			w.blurb = "Two cells, very fast, past light plate - and the venom creeps on."
			w.pattern = [Vector2i(0, 0), Vector2i(1, 0)]
			w.damage = 1
			w.penetration = 3
			w.armor_break = 1
			w.poison = 2
			w.kind = WeaponData.Kind.THRUST
			w.cooldown = 0.20
			w.windup = 0.03
			w.reach = 26.0
			w.arc_deg = 60.0
			w.knockback = 40.0
			w.shake = 0.5
			w.hitstop = 0.02
			w.max_targets = 1
			w.icon_name = "icon_dagger"
			w.fx = "fx_thrust"
			w.sfx = "thrust"
		BOW:
			w.display_name = "Bow"
			w.blurb = "One cell, at any range. Pick the cell you want."
			w.pattern = [Vector2i(0, 0)]
			w.damage = 1
			w.penetration = 2
			w.armor_break = 1
			w.kind = WeaponData.Kind.SHOOT
			w.cooldown = 0.50
			w.windup = 0.10
			w.reach = 220.0
			w.arc_deg = 10.0
			w.knockback = 30.0
			w.shake = 0.4
			w.hitstop = 0.0
			w.max_targets = 1
			w.icon_name = "icon_bow"
			w.fx = ""
			w.sfx = "shoot"
	return w


## Attacks used by enemies. They run through the same resolver the player
## does, so being hit reads the same way as hitting.
static func enemy_attack(id: String) -> WeaponData:
	var w := WeaponData.new()
	w.id = id
	w.damage = 1
	w.penetration = 2
	w.armor_break = 1
	match id:
		"slime_touch":
			w.display_name = "Caustic Touch"
			w.pattern = [Vector2i(0, 0)]
			w.poison = 2
		"goblin_cut":
			w.display_name = "Cleaver"
			w.pattern = [Vector2i(0, 0), Vector2i(1, 0)]
		"arrow":
			w.display_name = "Arrow"
			w.pattern = [Vector2i(0, 0)]
			w.penetration = 3
		"knight_smash":
			w.display_name = "Greatsword"
			w.pattern = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]
			w.penetration = 1
			w.armor_break = 2
		"boss_sweep":
			w.display_name = "Sovereign's Sweep"
			w.pattern = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)]
			w.penetration = 3
		"boss_orb":
			w.display_name = "Hollow Light"
			w.pattern = [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 2)]
			w.penetration = 2
	return w
