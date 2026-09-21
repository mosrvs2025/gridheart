extends SceneTree
## Headless checks for the parts of the game that are pure logic: the health
## grid, weapon patterns and the resolver.
##   godot --headless --script tests/test_core.gd

var failures := 0


func _init() -> void:
	_check_patterns()
	_check_direction()
	_check_armor()
	_check_poison()
	_check_growth_and_heal()
	_check_enemy_shapes()
	print("")
	if failures == 0:
		print("all checks passed")
	else:
		print("%d CHECK(S) FAILED" % failures)
	quit(1 if failures > 0 else 0)


func ok(label: String, condition: bool) -> void:
	print("  %s %s" % ["PASS" if condition else "FAIL", label])
	if not condition:
		failures += 1


func render(grid: HealthGrid) -> String:
	var out := ""
	var r := grid.used_rect()
	for y in r.size.y:
		var line := ""
		for x in r.size.x:
			var c: HealthCell = grid.get_cell(r.position + Vector2i(x, y))
			if c == null:
				line += " "
			elif not c.alive:
				line += "."
			elif c.poison > 0:
				line += "!"
			elif c.armor > 0:
				line += "@"
			else:
				line += "#"
		out += line + "\n"
	return out


func _check_patterns() -> void:
	print("\nweapon patterns")
	var sword := Weapons.make(Weapons.SWORD)
	ok("sword is a 4x1 row", CombatResolver.pattern_bounds(sword.pattern) == Vector2i(4, 1))
	var turned := CombatResolver.rotate_pattern(sword.pattern, 1)
	ok("a quarter turn makes it a 1x4 column", CombatResolver.pattern_bounds(turned) == Vector2i(1, 4))
	var back := CombatResolver.rotate_pattern(sword.pattern, 4)
	ok("four turns come back to the start", back == sword.pattern)
	ok("hammer is a 2x2 block",
		CombatResolver.pattern_bounds(Weapons.make(Weapons.HAMMER).pattern) == Vector2i(2, 2))


func _check_direction() -> void:
	print("\nattack direction decides which cells are taken")
	var grid := HealthGrid.from_ascii(["####", "####", "####"])
	var sword := Weapons.make(Weapons.SWORD)
	# struck from the left, high up: the top row should go
	var res := CombatResolver.resolve(grid, sword, Vector2.RIGHT, Vector2(-10, -9), 10.0)
	print(render(grid))
	ok("a level slash from the left takes four cells", res.destroyed.size() == 4)
	ok("...and they are the top row", grid.get_cell(Vector2i(0, 0)).alive == false \
		and grid.get_cell(Vector2i(3, 0)).alive == false \
		and grid.get_cell(Vector2i(0, 1)).alive)

	var grid2 := HealthGrid.from_ascii(["####", "####", "####"])
	var spear := Weapons.make(Weapons.SPEAR)
	var res2 := CombatResolver.resolve(grid2, spear, Vector2.RIGHT, Vector2(-10, 0), 10.0)
	print(render(grid2))
	ok("the spear's column only reaches three rows here", res2.destroyed.size() == 3)
	ok("...in a single column", grid2.get_cell(Vector2i(0, 0)).alive == false \
		and grid2.get_cell(Vector2i(0, 2)).alive == false \
		and grid2.get_cell(Vector2i(1, 1)).alive)

	var grid3 := HealthGrid.from_ascii(["####", "####", "####"])
	var res3 := CombatResolver.resolve(grid3, spear, Vector2.DOWN, Vector2(0, -10), 10.0)
	print(render(grid3))
	ok("the same spear from above turns side-on and takes a row", res3.destroyed.size() == 3)
	ok("...wasting a cell over the edge because it struck dead centre", res3.missed == 1)

	# Standing one step to the left lines the same attack up exactly: where you
	# stand changes the take, which is the whole point of the system.
	var grid4 := HealthGrid.from_ascii(["####", "####", "####"])
	var res4 := CombatResolver.resolve(grid4, spear, Vector2.DOWN, Vector2(-3, -10), 10.0)
	print(render(grid4))
	ok("a step to the left lands all four", res4.destroyed.size() == 4)

	var wide := HealthGrid.from_ascii(["########"])
	var r5 := CombatResolver.resolve(wide, Weapons.make(Weapons.SWORD), Vector2.RIGHT,
		Vector2(-10, 0), 10.0)
	print(render(wide))
	ok("a long thin body loses four to a level slash", r5.destroyed.size() == 4)
	var thin := HealthGrid.from_ascii(["########"])
	var r6 := CombatResolver.resolve(thin, Weapons.make(Weapons.SPEAR), Vector2.RIGHT,
		Vector2(-10, 0), 10.0)
	ok("but the spear, cutting across the swing, only finds one", r6.destroyed.size() == 1)


func _check_armor() -> void:
	print("\narmour")
	var knight := HealthGrid.from_ascii(["@@@", "@#@", "@#@"])
	var hammer := Weapons.make(Weapons.HAMMER)
	var res := CombatResolver.resolve(knight, hammer, Vector2.RIGHT, Vector2(-10, -9), 10.0)
	ok("the hammer shatters plate rather than piercing it", res.chipped.size() > 0)
	ok("...and the cell survives the first blow", knight.get_cell(Vector2i(0, 0)).alive)
	var res2 := CombatResolver.resolve(knight, hammer, Vector2.RIGHT, Vector2(-10, -9), 10.0)
	print(render(knight))
	ok("a second blow breaks the bared cells", res2.destroyed.size() > 0)

	var knight2 := HealthGrid.from_ascii(["@@@", "@#@", "@#@"])
	var dagger := Weapons.make(Weapons.DAGGER)
	var res3 := CombatResolver.resolve(knight2, dagger, Vector2.RIGHT, Vector2(-10, -9), 10.0)
	ok("the dagger slips past plate in one hit", res3.pierced.size() > 0 and res3.destroyed.size() > 0)

	var knight3 := HealthGrid.from_ascii(["@@@", "@#@", "@#@"])
	var res5 := CombatResolver.resolve(knight3, Weapons.make(Weapons.SWORD), Vector2.RIGHT,
		Vector2(-10, -9), 10.0)
	ok("the sword has to break plate open first",
		res5.destroyed.is_empty() and (res5.chipped.size() > 0 or res5.blocked.size() > 0))

	var shell := HealthGrid.from_ascii(["@#@"])
	var res6 := CombatResolver.resolve(shell, Weapons.make(Weapons.SWORD), Vector2.RIGHT,
		Vector2(-10, 0), 10.0)
	ok("plate that holds stops the blow behind it",
		res6.destroyed.is_empty() and shell.get_cell(Vector2i(1, 0)).alive)

	var plated := HealthGrid.from_ascii(["AA"])
	var sword := Weapons.make(Weapons.SWORD)
	var res4 := CombatResolver.resolve(plated, sword, Vector2.RIGHT, Vector2(-10, 0), 10.0)
	ok("the sword cannot pierce double plate", res4.blocked.size() > 0 and res4.destroyed.is_empty())


func _check_poison() -> void:
	print("\npoison")
	var grid := HealthGrid.from_ascii(["####", "####"])
	grid.get_cell(Vector2i(0, 0)).poison = 3
	var before := grid.alive_count()
	grid.tick(HealthGrid.POISON_INTERVAL + 0.01)
	print(render(grid))
	ok("a tick eats the poisoned cell", grid.alive_count() == before - 1)
	ok("...and leaves the infection in a neighbour", grid.has_poison())
	var fresh := HealthGrid.from_ascii(["###", "###"])
	var venom := Weapons.make(Weapons.DAGGER)
	var vres := CombatResolver.resolve(fresh, venom, Vector2.RIGHT, Vector2(-10, -9), 10.0)
	ok("a venomed blow leaves rot even when it kills what it touched",
		vres.destroyed.size() > 0 and fresh.has_poison())

	var steps := 0
	while grid.has_poison() and steps < 10:
		grid.tick(HealthGrid.POISON_INTERVAL + 0.01)
		steps += 1
	print(render(grid))
	ok("three stacks eat three cells and stop", grid.alive_count() == before - 3)


func _check_growth_and_heal() -> void:
	print("\ngrowth and mending")
	var grid := HealthGrid.seeded(9, 2, 2)
	ok("a new run starts with four cells", grid.alive_count() == 4)
	var rect := grid.used_rect()
	var bar := [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)]
	var above := Vector2i(rect.position.x, rect.position.y - 1)
	ok("growth may be attached against the body", grid.can_attach(bar, above))
	ok("growth may not float free", not grid.can_attach(bar, above - Vector2i(0, 3)))
	ok("growth may not overlap the body", not grid.can_attach(bar, rect.position))
	grid.attach(bar, above)
	ok("attaching grew the grid", grid.alive_count() == 7)

	var cell := grid.get_cell(rect.position)
	cell.alive = false
	ok("mending only fits over broken cells", grid.can_heal([Vector2i(0, 0)], rect.position))
	ok("...and not over living ones",
		not grid.can_heal([Vector2i(0, 0)], rect.position + Vector2i(1, 0)))
	grid.heal([Vector2i(0, 0)], rect.position)
	ok("mending restores the cell", grid.get_cell(rect.position).alive)

	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var whole := HealthGrid.seeded(9, 2, 2)
	ok("an unbroken grid is offered no mend", Shapes.pick_heal(rng, whole).is_empty())
	var one_hole := HealthGrid.seeded(9, 2, 2)
	var origin := one_hole.used_rect().position
	one_hole.get_cell(origin).alive = false
	ok("a single hole is too small for any mend, so none is offered",
		Shapes.pick_heal(rng, one_hole).is_empty())

	var two_holes := HealthGrid.seeded(9, 2, 2)
	two_holes.get_cell(origin).alive = false
	two_holes.get_cell(origin + Vector2i(1, 0)).alive = false
	var offer := Shapes.pick_heal(rng, two_holes)
	ok("two holes are offered a mend that fits them",
		not offer.is_empty() and Shapes.fits(two_holes, offer.cells, true))


func _check_enemy_shapes() -> void:
	print("\nenemy layouts")
	for id in EnemyData.TABLE:
		var data: Dictionary = EnemyData.get_data(id)
		var grid := HealthGrid.from_ascii(data.grid)
		ok("%s has a body of %d cells" % [data.name, grid.total_count()], grid.total_count() > 0)
	var boss := HealthGrid.from_ascii(EnemyData.get_data("boss").grid)
	ok("the boss has armoured flanks and a plated core",
		boss.get_cell(Vector2i(0, 0)).armor > 0 and boss.get_cell(Vector2i(3, 2)).armor == 2)
