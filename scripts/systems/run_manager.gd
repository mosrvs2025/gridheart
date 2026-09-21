extends Node
## Run-wide state: which room we are in, the run's rng, and a few numbers for
## the end screen.

var room_index := 0
var rooms_cleared := 0
var cells_destroyed := 0
var cells_lost := 0
var started_at := 0.0
var rng := RandomNumberGenerator.new()
var unlocked: Array[String] = []


func start() -> void:
	room_index = 0
	rooms_cleared = 0
	cells_destroyed = 0
	cells_lost = 0
	unlocked.clear()
	rng.randomize()
	started_at = Time.get_ticks_msec() / 1000.0


func elapsed() -> float:
	return Time.get_ticks_msec() / 1000.0 - started_at


func elapsed_text() -> String:
	var t := int(elapsed())
	return "%d:%02d" % [t / 60, t % 60]
