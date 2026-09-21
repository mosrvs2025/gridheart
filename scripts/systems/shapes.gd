class_name Shapes
extends RefCounted
## Growth and healing shapes, and the helpers menus need to draw and turn them.

const GROWTH := [
	{"name": "Bar", "cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)]},
	{"name": "Column", "cells": [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2)]},
	{"name": "Block", "cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]},
	{"name": "Elbow", "cells": [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1)]},
	{"name": "Tee", "cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1)]},
	{"name": "Step", "cells": [Vector2i(0, 1), Vector2i(1, 1), Vector2i(1, 0), Vector2i(2, 0)]},
	{"name": "Pair", "cells": [Vector2i(0, 0), Vector2i(1, 0)]},
	{"name": "Hook", "cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(2, 1)]},
]

const HEAL := [
	{"name": "Salve", "cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1)]},
	{"name": "Poultice", "cells": [Vector2i(0, 0), Vector2i(1, 0)]},
	{"name": "Draught", "cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]},
	{"name": "Tonic", "cells": [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2)]},
]


static func normalize(cells: Array) -> Array:
	var mn := Vector2i(9999, 9999)
	for c in cells:
		mn = mn.min(c)
	var out := []
	for c in cells:
		out.append(c - mn)
	return out


static func rotate(cells: Array, steps: int = 1) -> Array:
	var out := []
	for c in cells:
		var q: Vector2i = c
		for i in posmod(steps, 4):
			q = Vector2i(-q.y, q.x)
		out.append(q)
	return normalize(out)


static func size_of(cells: Array) -> Vector2i:
	var mx := Vector2i.ZERO
	for c in cells:
		mx = mx.max(c)
	return mx + Vector2i.ONE


static func pick_growth(count: int, rng: RandomNumberGenerator) -> Array:
	var pool := GROWTH.duplicate()
	var out := []
	for i in count:
		if pool.is_empty():
			break
		var idx := rng.randi_range(0, pool.size() - 1)
		var entry: Dictionary = pool[idx]
		pool.remove_at(idx)
		out.append({"name": entry.name, "cells": entry.cells.duplicate()})
	return out


## True when the shape has at least one legal home on the grid, in any turn.
static func fits(grid: HealthGrid, cells: Array, heal: bool) -> bool:
	for turn in 4:
		var turned := rotate(cells, turn)
		for y in grid.height:
			for x in grid.width:
				var at := Vector2i(x, y)
				if heal:
					if grid.can_heal(turned, at):
						return true
				elif grid.can_attach(turned, at):
					return true
	return false


## Offers a mend the wounds can actually take. Handing the player a shape too
## big for the holes in their grid is just a screen they cannot answer.
static func pick_heal(rng: RandomNumberGenerator, grid: HealthGrid) -> Dictionary:
	var usable := []
	for entry in HEAL:
		if fits(grid, entry.cells, true):
			usable.append(entry)
	if usable.is_empty():
		return {}
	var entry: Dictionary = usable[rng.randi_range(0, usable.size() - 1)]
	return {"name": entry.name, "cells": entry.cells.duplicate()}
