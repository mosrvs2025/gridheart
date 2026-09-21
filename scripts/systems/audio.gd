extends Node
## A small pooled player for the generated one-shot sounds.

const POOL := 12

var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in POOL:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_players.append(p)


func play(name: String, volume_db := -6.0, pitch := 1.0) -> void:
	if not _streams.has(name):
		var path := "res://assets/sfx/%s.wav" % name
		_streams[name] = load(path) if ResourceLoader.exists(path) else null
	var s: AudioStream = _streams[name]
	if s == null:
		return
	var p := _players[_next]
	_next = (_next + 1) % POOL
	p.stream = s
	p.volume_db = volume_db
	p.pitch_scale = pitch * randf_range(0.96, 1.04)
	p.play()
