extends Node
## Loads sprite strips into SpriteFrames and hands out shared textures.
##
## Every character strip is a horizontal row of square frames, so the frame
## size is simply the image height.

const ANIM_SPEC := {
	"idle": [5.0, true],
	"run": [10.0, true],
	"attack": [14.0, false],
	"hurt": [8.0, false],
	"death": [9.0, false],
	"broken": [5.0, true],
}

var _cache: Dictionary = {}
var _frames_cache: Dictionary = {}


func tex(name: String) -> Texture2D:
	if not _cache.has(name):
		var path := "res://assets/%s.png" % name
		_cache[name] = load(path) if ResourceLoader.exists(path) else null
	return _cache[name]


## Slices a strip into AtlasTextures, one per frame.
func slice(name: String) -> Array[Texture2D]:
	var out: Array[Texture2D] = []
	var t := tex(name)
	if t == null:
		return out
	var h := t.get_height()
	var count := int(t.get_width() / float(h))
	for i in count:
		var at := AtlasTexture.new()
		at.atlas = t
		at.region = Rect2(i * h, 0, h, h)
		at.filter_clip = true
		out.append(at)
	return out


## Slices a strip of non-square frames, `count` frames wide.
func slice_n(name: String, count: int) -> Array[Texture2D]:
	var out: Array[Texture2D] = []
	var t := tex(name)
	if t == null:
		return out
	var w := t.get_width() / float(count)
	for i in count:
		var at := AtlasTexture.new()
		at.atlas = t
		at.region = Rect2(i * w, 0, w, t.get_height())
		at.filter_clip = true
		out.append(at)
	return out


func frames_for(prefix: String) -> SpriteFrames:
	if _frames_cache.has(prefix):
		return _frames_cache[prefix]
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	for anim in ANIM_SPEC:
		var strip := slice("%s_%s" % [prefix, anim])
		if strip.is_empty():
			continue
		sf.add_animation(anim)
		sf.set_animation_speed(anim, ANIM_SPEC[anim][0])
		sf.set_animation_loop(anim, ANIM_SPEC[anim][1])
		for f in strip:
			sf.add_frame(anim, f)
	_frames_cache[prefix] = sf
	return sf
