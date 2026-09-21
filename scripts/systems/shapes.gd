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
		out.append({"name": entry.name, "cells": rotate(entry.cells, rng.randi_range(0, 3))})
	return out


static func pick_heal(rng: RandomNumberGenerator) -> Dictionary:
	var entry: Dictionary = HEAL[rng.randi_range(0, HEAL.size() - 1)]
	return {"name": entry.name, "cells": entry.cells.duplicate()}
