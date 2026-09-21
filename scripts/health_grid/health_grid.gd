class_name HealthGrid
extends RefCounted
## A combatant's health, laid out in two dimensions.
##
## The grid is pure game data: it holds cells, applies weapon patterns to them
## and spreads status effects. It has no idea what the character on screen
## looks like, and the character has no idea what shape its health is.

signal changed
signal cells_hit(coords: Array)
signal cells_destroyed(coords: Array)
signal armor_broken(coords: Array)
signal blocked(coords: Array)
signal poison_spread(coords: Array)
signal emptied

const POISON_INTERVAL := 1.15

var width: int = 1
var height: int = 1
var cells: Array = []        ## row-major; null means "not part of this body"
var poison_timer: float = 0.0


func _init(w: int = 1, h: int = 1) -> void:
	_allocate(w, h)


func _allocate(w: int, h: int) -> void:
	width = w
	height = h
	cells = []
	for y in h:
		var row := []
		row.resize(w)
		cells.append(row)


## Builds a grid from the ASCII layouts the design doc is written in.
##   '#' normal cell   '@' armoured (1)   'A' heavily armoured (2)
##   'o' already destroyed   '.' or ' ' not part of the body
static func from_ascii(rows: Array) -> HealthGrid:
	var w := 0
	for r in rows:
		w = maxi(w, String(r).length())
	var g := HealthGrid.new(w, rows.size())
	for y in rows.size():
		var line := String(rows[y])
		for x in line.length():
			match line[x]:
				"#":
					g.cells[y][x] = HealthCell.new(HealthCell.Kind.NORMAL, 1, 0)
				"=":
					g.cells[y][x] = HealthCell.new(HealthCell.Kind.NORMAL, 2, 0)
				"@":
					g.cells[y][x] = HealthCell.new(HealthCell.Kind.ARMORED, 1, 1)
				"A":
					g.cells[y][x] = HealthCell.new(HealthCell.Kind.ARMORED, 1, 2)
				"o":
					var c := HealthCell.new()
					c.alive = false
					g.cells[y][x] = c
	return g


## An empty canvas of the given size with a block of cells in the middle -
## how the player's grid starts before any growth is attached.
static func seeded(canvas: int, seed_w: int, seed_h: int) -> HealthGrid:
	var g := HealthGrid.new(canvas, canvas)
	var ox := int((canvas - seed_w) / 2.0)
	var oy := int((canvas - seed_h) / 2.0)
	for y in seed_h:
		for x in seed_w:
			g.cells[oy + y][ox + x] = HealthCell.new()
	return g


func in_bounds(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < width and c.y < height


func get_cell(c: Vector2i) -> HealthCell:
	if not in_bounds(c):
		return null
	return cells[c.y][c.x]


func set_cell(c: Vector2i, cell: HealthCell) -> void:
	if in_bounds(c):
		cells[c.y][c.x] = cell


func occupied_coords() -> Array:
	var out := []
	for y in height:
		for x in width:
			if cells[y][x] != null:
				out.append(Vector2i(x, y))
	return out


func alive_count() -> int:
	var n := 0
	for y in height:
		for x in width:
			var c: HealthCell = cells[y][x]
			if c != null and c.alive:
				n += 1
	return n


func total_count() -> int:
	return occupied_coords().size()


## The sub-rectangle actually in use, so views can draw a 9x9 canvas that
## only holds a 3x2 body without a cloud of empty space around it.
func used_rect() -> Rect2i:
	var occ := occupied_coords()
	if occ.is_empty():
		return Rect2i(0, 0, 0, 0)
	var mn := Vector2i(width, height)
	var mx := Vector2i(-1, -1)
	for c in occ:
		mn = mn.min(c)
		mx = mx.max(c)
	return Rect2i(mn, mx - mn + Vector2i.ONE)


# ---------------------------------------------------------------- damage
## Applies a weapon's pattern with its top-left at `origin`, biting in along
## `dir`. Plate that holds stops the rest of the blow behind it, so an
## armoured shell has to be opened before the soft middle can be reached.
## Returns what happened, so the caller can play the right feedback.
func apply_pattern(pattern: Array, origin: Vector2i, weapon, dir := Vector2i.RIGHT) -> Dictionary:
	var res := {
		"hit": [], "destroyed": [], "blocked": [], "chipped": [],
		"pierced": [], "poisoned": [], "missed": 0, "cells": pattern.size(),
	}
	var stopped := {}
	for off in _ordered(pattern, dir):
		var c: Vector2i = origin + off
		var lane: int = c.y if dir.x != 0 else c.x
		if stopped.has(lane):
			res.missed += 1
			continue
		var cell: HealthCell = get_cell(c)
		if cell == null or not cell.alive:
			res.missed += 1
			continue
		if cell.armor > 0:
			# Only a properly piercing weapon slips past plate; everything else
			# has to break it open first.
			if weapon.penetration > cell.armor + 1:
				res.pierced.append(c)
				_wound(cell, c, weapon, res)
			else:
				cell.armor -= weapon.armor_break
				if cell.armor <= 0:
					cell.armor = 0
					res.chipped.append(c)
				else:
					res.blocked.append(c)
				stopped[lane] = true
			continue
		_wound(cell, c, weapon, res)
	if weapon.poison > 0 and res.poisoned.is_empty():
		_seed_poison(res, weapon.poison)
	_announce(res)
	return res


## A venomous blow that killed everything it touched still leaves rot behind:
## it takes in a living cell beside the wound instead.
func _seed_poison(res: Dictionary, stacks: int) -> void:
	for dead in res.destroyed:
		var n := _clean_neighbour(dead)
		if n != Vector2i(-1, -1):
			get_cell(n).poison = stacks
			res.poisoned.append(n)
			return


## Pattern cells sorted so the ones nearest the struck face resolve first.
func _ordered(pattern: Array, dir: Vector2i) -> Array:
	var out: Array = pattern.duplicate()
	if dir.x > 0:
		out.sort_custom(func(a, b): return a.x < b.x)
	elif dir.x < 0:
		out.sort_custom(func(a, b): return a.x > b.x)
	elif dir.y > 0:
		out.sort_custom(func(a, b): return a.y < b.y)
	else:
		out.sort_custom(func(a, b): return a.y > b.y)
	return out


func _wound(cell: HealthCell, c: Vector2i, weapon, res: Dictionary) -> void:
	cell.hp -= weapon.damage
	if cell.hp <= 0:
		cell.alive = false
		cell.poison = 0
		res.destroyed.append(c)
	else:
		res.hit.append(c)
		if weapon.poison > 0:
			cell.poison = maxi(cell.poison, weapon.poison)
			res.poisoned.append(c)
			if not res.has("poison_sound"):
				res["poison_sound"] = true


func _announce(res: Dictionary) -> void:
	if not res.blocked.is_empty():
		blocked.emit(res.blocked)
	if not res.chipped.is_empty():
		armor_broken.emit(res.chipped)
	var touched: Array = res.hit + res.pierced
	if not touched.is_empty():
		cells_hit.emit(touched)
	if not res.destroyed.is_empty():
		cells_destroyed.emit(res.destroyed)
	if not res.poisoned.is_empty():
		poison_spread.emit(res.poisoned)
	if not res.destroyed.is_empty() or not res.hit.is_empty() or not res.chipped.is_empty():
		changed.emit()
	if alive_count() == 0:
		emptied.emit()


## Direct infection, used by enemies whose touch is venomous.
func infect(c: Vector2i, stacks: int) -> void:
	var cell := get_cell(c)
	if cell != null and cell.alive:
		cell.poison = maxi(cell.poison, stacks)
		poison_spread.emit([c])
		changed.emit()


func has_poison() -> bool:
	for y in height:
		for x in width:
			var c: HealthCell = cells[y][x]
			if c != null and c.alive and c.poison > 0:
				return true
	return false


## Poison eats one cell per tick and creeps into a neighbour before it goes,
## so an infection carves a path through the body rather than ticking a number.
func tick(delta: float) -> void:
	if not has_poison():
		poison_timer = 0.0
		return
	poison_timer += delta
	if poison_timer < POISON_INTERVAL:
		return
	poison_timer = 0.0
	var infected := []
	for y in height:
		for x in width:
			var c: HealthCell = cells[y][x]
			if c != null and c.alive and c.poison > 0:
				infected.append(Vector2i(x, y))
	var spread := []
	var killed := []
	for coord in infected:
		var cell: HealthCell = get_cell(coord)
		if cell == null or not cell.alive:
			continue
		if cell.poison > 1:
			var target := _clean_neighbour(coord)
			if target != Vector2i(-1, -1):
				get_cell(target).poison = cell.poison - 1
				spread.append(target)
		cell.hp -= 1
		if cell.hp <= 0:
			cell.alive = false
			cell.poison = 0
			killed.append(coord)
	if not spread.is_empty():
		poison_spread.emit(spread)
	if not killed.is_empty():
		cells_destroyed.emit(killed)
	changed.emit()
	if alive_count() == 0:
		emptied.emit()


func _clean_neighbour(c: Vector2i) -> Vector2i:
	var opts := []
	for d in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]:
		var n: Vector2i = c + d
		var cell := get_cell(n)
		if cell != null and cell.alive and cell.poison == 0:
			opts.append(n)
	if opts.is_empty():
		return Vector2i(-1, -1)
	return opts[randi() % opts.size()]


# ---------------------------------------------------------------- repair & growth
## True when every coord in the shape lands on a destroyed cell of this body.
func can_heal(shape: Array, origin: Vector2i) -> bool:
	for off in shape:
		var cell := get_cell(origin + off)
		if cell == null or cell.alive:
			return false
	return true


func heal(shape: Array, origin: Vector2i) -> void:
	for off in shape:
		var cell := get_cell(origin + off)
		if cell != null and not cell.alive:
			cell.alive = true
			cell.hp = cell.max_hp
			cell.armor = cell.max_armor
			cell.poison = 0
	changed.emit()


## New growth has to sit on empty canvas and touch the body somewhere.
func can_attach(shape: Array, origin: Vector2i) -> bool:
	var touches := false
	for off in shape:
		var c: Vector2i = origin + off
		if not in_bounds(c) or get_cell(c) != null:
			return false
		for d in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]:
			if get_cell(c + d) != null:
				touches = true
	return touches


func attach(shape: Array, origin: Vector2i) -> void:
	for off in shape:
		set_cell(origin + off, HealthCell.new())
	changed.emit()


func duplicate_grid() -> HealthGrid:
	var g := HealthGrid.new(width, height)
	for y in height:
		for x in width:
			var c: HealthCell = cells[y][x]
			g.cells[y][x] = c.duplicate_cell() if c != null else null
	return g
