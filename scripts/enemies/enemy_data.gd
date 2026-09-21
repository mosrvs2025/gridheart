class_name EnemyData
extends RefCounted
## Enemy definitions. The health layout is as much a part of an enemy's
## identity as its behaviour - a wide body and a narrow body want to be
## fought with different weapons.

const TABLE := {
	"slime": {
		"name": "Slime",
		"sprite": "slime",
		"grid": ["###", "###"],
		"speed": 34.0,
		"radius": 9.0,
		"attack": "slime_touch",
		"attack_range": 17.0,
		"windup": 0.34,
		"recover": 0.75,
		"hop": true,
		"contact": true,
		"score": 1,
	},
	"goblin": {
		"name": "Goblin",
		"sprite": "goblin",
		"grid": ["####", "####", "##"],
		"speed": 74.0,
		"radius": 8.0,
		"attack": "goblin_cut",
		"attack_range": 22.0,
		"windup": 0.26,
		"recover": 0.42,
		"score": 2,
	},
	"archer": {
		"name": "Archer",
		"sprite": "archer",
		"grid": ["###", ".##", "###"],
		"speed": 56.0,
		"radius": 8.0,
		"attack": "arrow",
		"attack_range": 132.0,
		"keep_distance": 96.0,
		"windup": 0.46,
		"recover": 1.05,
		"ranged": true,
		"score": 2,
	},
	"knight": {
		"name": "Armoured Knight",
		"sprite": "knight",
		"grid": ["@@@", "@#@", "@#@"],
		"speed": 40.0,
		"radius": 9.0,
		"attack": "knight_smash",
		"attack_range": 26.0,
		"windup": 0.62,
		"recover": 0.85,
		"heavy": true,
		"score": 4,
	},
	"boss": {
		"name": "The Hollow Sovereign",
		"sprite": "boss",
		"grid": [
			"@@####@@",
			"@######@",
			"###AA###",
			"########",
		],
		"speed": 44.0,
		"radius": 18.0,
		"attack": "boss_sweep",
		"attack_range": 40.0,
		"windup": 0.6,
		"recover": 0.7,
		"boss": true,
		"score": 20,
	},
}


static func get_data(id: String) -> Dictionary:
	return TABLE.get(id, TABLE["slime"])
