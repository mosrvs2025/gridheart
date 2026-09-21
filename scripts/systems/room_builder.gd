class_name RoomBuilder
extends RefCounted
## Turns an ASCII map into a room: one tilemap for floor and walls, sprites
## for props, and merged rectangles for collision.

const TILE := 16
const ATLAS_COLS := 8

enum {
	T_FLOOR_0, T_FLOOR_1, T_FLOOR_2, T_FLOOR_3,
	T_WALL_FACE, T_WALL_CAP, T_WALL_TOP, T_PILLAR,
	T_CRATE, T_RUG, T_DOOR_SHUT, T_DOOR_OPEN,
	T_TORCH_0, T_TORCH_1, T_BONES, T_GRASS,
}

const SOLID := " #pc"


static func tile_region(index: int) -> Rect2:
	return Rect2((index % ATLAS_COLS) * TILE, int(index / float(ATLAS_COLS)) * TILE, TILE, TILE)


static func tile_tex(index: int) -> AtlasTexture:
	var at := AtlasTexture.new()
	at.atlas = Art.tex("tiles")
	at.region = tile_region(index)
	at.filter_clip = true
	return at


## Builds the room under `root` and returns its metadata (spawn points, door,
## bounds) for the game to use.
static func build(root: Node2D, room: Dictionary) -> Dictionary:
	var map: Array = room.map
	var h := map.size()
	var w := 0
	for line in map:
		w = maxi(w, String(line).length())

	var info := {
		"width": w, "height": h,
		"bounds": Rect2(0, 0, w * TILE, h * TILE),
		"player_start": Vector2(TILE * 3, TILE * 8),
		"door": Vector2(TILE * (w - 3), TILE * 8),
		"door_tile": Vector2i(w - 3, 8),
		"spawn_points": {},
		"shrine": Vector2.ZERO,
		"pedestal": Vector2.ZERO,
		"solid": [],
	}

	var floor_layer := Node2D.new()
	floor_layer.name = "Floor"
	floor_layer.z_index = -20
	root.add_child(floor_layer)

	var prop_layer := Node2D.new()
	prop_layer.name = "Props"
	prop_layer.y_sort_enabled = true
	root.add_child(prop_layer)

	var solid_rows := []
	for y in h:
		var line: String = String(map[y])
		var row := []
		for x in w:
			var ch := line[x] if x < line.length() else "#"
			row.append(ch == "#" or ch == " ")
			_place(floor_layer, prop_layer, info, ch, x, y, map, w, h)
		solid_rows.append(row)

	info.solid = solid_rows
	_add_collision(root, solid_rows, w, h)
	return info


static func _sprite(parent: Node2D, tile: int, x: int, y: int, z := 0) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = tile_tex(tile)
	s.centered = false
	s.position = Vector2(x * TILE, y * TILE)
	s.z_index = z
	parent.add_child(s)
	return s


static func _place(floor_layer: Node2D, props: Node2D, info: Dictionary, ch: String,
		x: int, y: int, map: Array, w: int, h: int) -> void:
	var centre := Vector2(x * TILE + TILE * 0.5, y * TILE + TILE * 0.5)
	if ch == "#" or ch == " ":
		var below := String(map[y + 1]) if y + 1 < h else "#"
		var below_ch := below[x] if x < below.length() else "#"
		var is_face := not (below_ch == "#" or below_ch == " ")
		_sprite(floor_layer, T_WALL_CAP if is_face else T_WALL_TOP, x, y, -18)
		return
	# every non-wall tile gets a floor under it
	_sprite(floor_layer, [T_FLOOR_0, T_FLOOR_1, T_FLOOR_2, T_FLOOR_3][(x * 7 + y * 5) % 4], x, y, -20)
	match ch:
		"P":
			info.player_start = centre
		"D":
			info.door = centre
			info.door_tile = Vector2i(x, y)
		"r":
			_sprite(floor_layer, T_RUG, x, y, -19)
		"p":
			var pil := _sprite(props, T_PILLAR, x, y)
			pil.y_sort_enabled = true
			pil.offset = Vector2(0, -6)
		"c":
			_sprite(props, T_CRATE, x, y)
		"b":
			_sprite(floor_layer, T_BONES, x, y, -19)
		"g":
			_sprite(floor_layer, T_GRASS, x, y, -19)
		"t":
			var s := AnimatedSprite2D.new()
			var sf := SpriteFrames.new()
			sf.set_animation_speed("default", 6.0)
			sf.add_frame("default", tile_tex(T_TORCH_0))
			sf.add_frame("default", tile_tex(T_TORCH_1))
			s.sprite_frames = sf
			s.centered = false
			s.position = Vector2(x * TILE, y * TILE - 4)
			s.play()
			props.add_child(s)
			var light := Sprite2D.new()
			light.texture = Art.tex("shadow")
			light.position = centre + Vector2(0, 10)
			light.scale = Vector2(2.2, 2.2)
			light.modulate = Color(1.0, 0.76, 0.42, 0.13)
			light.z_index = -17
			props.add_child(light)
		"S":
			info.shrine = centre
		"W":
			info.pedestal = centre
		"?":
			pass
		_:
			if ch.is_valid_int() and ch != "0":
				info.spawn_points[int(ch)] = centre


## Merges runs of solid tiles into as few rectangles as the room allows.
static func _add_collision(root: Node2D, solid: Array, w: int, h: int) -> void:
	var body := StaticBody2D.new()
	body.name = "Walls"
	body.collision_layer = 1
	body.collision_mask = 0
	root.add_child(body)
	var used := []
	for y in h:
		var row := []
		row.resize(w)
		row.fill(false)
		used.append(row)
	for y in h:
		var x := 0
		while x < w:
			if not solid[y][x] or used[y][x]:
				x += 1
				continue
			var x2 := x
			while x2 + 1 < w and solid[y][x2 + 1] and not used[y][x2 + 1]:
				x2 += 1
			var y2 := y
			while y2 + 1 < h:
				var ok := true
				for xi in range(x, x2 + 1):
					if not solid[y2 + 1][xi] or used[y2 + 1][xi]:
						ok = false
						break
				if not ok:
					break
				y2 += 1
			for yi in range(y, y2 + 1):
				for xi in range(x, x2 + 1):
					used[yi][xi] = true
			var shape := CollisionShape2D.new()
			var rect := RectangleShape2D.new()
			rect.size = Vector2((x2 - x + 1) * TILE, (y2 - y + 1) * TILE)
			shape.shape = rect
			shape.position = Vector2(x * TILE, y * TILE) + rect.size * 0.5
			body.add_child(shape)
			x = x2 + 1
