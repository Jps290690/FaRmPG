class_name ResourceNode
extends Node2D

@export var resource_type := "wood"
@export var tool_required := "axe"
@export var skill := "tala"
@export var max_amount := 4
@export var respawn_time := 12.0
@export var gather_time := 1.8
@export var base_yield := 1

var amount := 0
var harvestable := true

var TRUNK := PackedVector2Array([-8, -2, 8, -2, 5, 26, -5, 26])
var CANOPY := PackedVector2Array([0, -34, 26, 0, 0, 34, -26, 0])
var STUMP := PackedVector2Array([-8, 6, 8, 6, 5, 22, -5, 22])
var ROCK := PackedVector2Array([-22, 2, -14, -12, 2, -18, 18, -6, 18, 8, 0, 16, -16, 12])
var ROCK_DEAD := PackedVector2Array([-14, 6, -6, 0, 8, 0, 12, 8, -4, 12])
var BUSH_A := PackedVector2Array([-18, 4, -6, -10, 8, -8, 16, 2, 6, 14, -10, 12])
var BUSH_B := PackedVector2Array([-4, -2, 4, -6, 12, 0, 6, 8, -2, 6])
var BUSH_DEAD := PackedVector2Array([-4, 6, 4, 2, 6, 10, -2, 12])
var DEER := PackedVector2Array([-16, 4, -10, -14, 10, -16, 16, -2, 14, 14, 4, 18, -12, 12])
var DEER_HEAD := PackedVector2Array([10, -16, 20, -20, 18, -10, 12, -10])

var _main := Node2D.new()
var _depleted := Node2D.new()
var _timer: Timer

func _ready() -> void:
	amount = max_amount
	harvestable = true
	_depleted.visible = false
	add_child(_main)
	add_child(_depleted)
	_timer = Timer.new()
	_timer.one_shot = true
	_timer.wait_time = respawn_time
	_timer.timeout.connect(_respawn)
	add_child(_timer)
	_build_visuals()

func _build_visuals() -> void:
	match resource_type:
		"wood":
			_poly(_main, TRUNK, Color("#6b4a2b"))
			_poly(_main, CANOPY, Color("#2f6b32"))
			_poly(_depleted, STUMP, Color("#6b4a2b"))
		"stone":
			_poly(_main, ROCK, Color("#8d929a"))
			_poly(_depleted, ROCK_DEAD, Color("#5a5f66"))
		"fiber":
			_poly(_main, BUSH_A, Color("#3f8f6b"))
			_poly(_main, BUSH_B, Color("#5fbf8b"))
			_poly(_depleted, BUSH_DEAD, Color("#2f6b52"))
		"leather":
			_poly(_main, DEER, Color("#b07d4f"))
			_poly(_main, DEER_HEAD, Color("#b07d4f"))

func _poly(parent: Node2D, pts: PackedVector2Array, color: Color) -> void:
	var p := Polygon2D.new()
	p.polygon = pts
	p.color = color
	parent.add_child(p)

func harvest_success() -> int:
	if amount <= 0:
		return 0
	amount -= 1
	if amount <= 0:
		_set_depleted()
	return amount

func _set_depleted() -> void:
	harvestable = false
	_main.visible = false
	_depleted.visible = true
	_timer.start()

func _respawn() -> void:
	amount = max_amount
	harvestable = true
	_main.visible = true
	_depleted.visible = false

func debug_state() -> String:
	return "type=%s tool=%s skill=%s amount=%d/%d harvestable=%s depleted_visible=%s" % [
		resource_type, tool_required, skill, amount, max_amount, harvestable, _depleted.visible,
	]
