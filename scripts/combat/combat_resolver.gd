class_name CombatResolver
extends RefCounted
## Turns a successful world-space hit into a placement of the weapon's shape
## on the target's health grid.
##
## Where you stand and which way you swing decides which cells you get, so
## positioning matters twice: once in the room, once inside the enemy.

## 0 = right, 1 = down, 2 = left, 3 = up.
static func dir_index(v: Vector2) -> int:
	if absf(v.x) >= absf(v.y):
		return 0 if v.x >= 0.0 else 2
	return 1 if v.y >= 0.0 else 3


static func dir_vector(index: int) -> Vector2i:
	return [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP][index]


## Rotates a pattern by 90 degree steps and re-seats it at (0,0).
static func rotate_pattern(pattern: Array, steps: int) -> Array:
	var out := []
	for p in pattern:
		var q: Vector2i = p
		for i in posmod(steps, 4):
			q = Vector2i(-q.y, q.x)
		out.append(q)
	var mn := Vector2i(9999, 9999)
	for p in out:
		mn = mn.min(p)
	var shifted := []
	for p in out:
		shifted.append(p - mn)
	return shifted


static func pattern_bounds(pattern: Array) -> Vector2i:
	var mx := Vector2i.ZERO
	for p in pattern:
		mx = mx.max(p)
	return mx + Vector2i.ONE


## Maps a hit somewhere on the target's body to a cell of its grid.
## `local` is the hit point relative to the target's centre; `extent` is
## roughly the target's half-size in pixels.
static func impact_cell(grid: HealthGrid, local: Vector2, extent: float) -> Vector2i:
	var rect := grid.used_rect()
	if rect.size.x == 0:
		return Vector2i.ZERO
	var n := Vector2(
		clampf(local.x / maxf(extent, 1.0), -1.0, 1.0),
		clampf(local.y / maxf(extent, 1.0), -1.0, 1.0))
	var col := rect.position.x + int(round((n.x * 0.5 + 0.5) * (rect.size.x - 1)))
	var row := rect.position.y + int(round((n.y * 0.5 + 0.5) * (rect.size.y - 1)))
	return Vector2i(col, row)


## Seats the rotated pattern so it bites inward from the struck edge.
static func origin_for(cell: Vector2i, pattern: Array, dir: Vector2i) -> Vector2i:
	var size := pattern_bounds(pattern)
	var o := cell
	if dir.x > 0:
		o.x = cell.x
	elif dir.x < 0:
		o.x = cell.x - (size.x - 1)
	else:
		o.x = cell.x - int((size.x - 1) / 2.0)
	if dir.y > 0:
		o.y = cell.y
	elif dir.y < 0:
		o.y = cell.y - (size.y - 1)
	else:
		o.y = cell.y - int((size.y - 1) / 2.0)
	return o


## Full resolution: rotate, place, damage. Returns the damage report plus the
## placement, so the view can flash exactly the cells that were struck.
static func resolve(grid: HealthGrid, weapon: WeaponData, hit_dir: Vector2,
		local: Vector2, extent: float) -> Dictionary:
	var index := dir_index(hit_dir)
	var pattern := rotate_pattern(weapon.pattern, index)
	var cell := impact_cell(grid, local, extent)
	var origin := origin_for(cell, pattern, dir_vector(index))
	var res := grid.apply_pattern(pattern, origin, weapon, dir_vector(index))
	res["pattern"] = pattern
	res["origin"] = origin
	res["impact"] = cell
	res["dir_index"] = index
	return res
