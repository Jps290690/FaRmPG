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

var _main := Node2D.new()
var _depleted := Node2D.new()
var _timer: Timer
var _variant := 0
var _sprite_main: Sprite2D
var _sprite_depleted: Sprite2D
var _bob_time := 0.0

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
	_variant = int(PixelArt.hash2(int(global_position.x), int(global_position.y)) * 2)
	_build_visuals()
	z_index = int(global_position.y)

func _build_visuals() -> void:
	match resource_type:
		"wood":
			var tree: Array = PixelArt.SPRITES["TREE_1"] if _variant == 0 else PixelArt.SPRITES["TREE_2"]
			_sprite_main = PixelArt.make_sprite(_main, tree, PixelArt.PAL, 2)
			_sprite_depleted = PixelArt.make_sprite(_depleted, PixelArt.SPRITES["STUMP"], PixelArt.PAL, 2)
		"stone":
			_sprite_main = PixelArt.make_sprite(_main, PixelArt.SPRITES["ROCK"], PixelArt.PAL, 2)
			_sprite_depleted = PixelArt.make_sprite(_depleted, PixelArt.SPRITES["ROCK_DEAD"], PixelArt.PAL, 2)
		"mineral":
			_sprite_main = PixelArt.make_sprite(_main, PixelArt.SPRITES["MINERAL"], PixelArt.PAL, 2)
			_sprite_depleted = PixelArt.make_sprite(_depleted, PixelArt.SPRITES["MINERAL_DEAD"], PixelArt.PAL, 2)
		"fiber":
			_sprite_main = PixelArt.make_sprite(_main, PixelArt.SPRITES["BUSH"], PixelArt.PAL, 2)
			_sprite_depleted = PixelArt.make_sprite(_depleted, PixelArt.SPRITES["BUSH_DEAD"], PixelArt.PAL, 2)
		"leather":
			_sprite_main = PixelArt.make_sprite(_main, PixelArt.SPRITES["DEER"], PixelArt.PAL, 2)
	PixelArt.make_shadow(self, 30, 10)

func _physics_process(delta: float) -> void:
	# El ciervo respira suavemente mientras está vivo.
	if resource_type == "leather" and harvestable and _sprite_main:
		_bob_time += delta
		_sprite_main.position.y = -float(_sprite_main.texture.get_height()) + sin(_bob_time * 6.0) * 1.5

func harvest_success() -> int:
	if amount <= 0:
		return 0
	amount -= 1
	if amount <= 0:
		_set_depleted()
	return amount

# Sacudida del recurso + partículas al recolectar (juiciness).
func play_harvest_fx() -> void:
	if _main.visible:
		var tween := create_tween()
		tween.set_loops(3)
		tween.tween_property(_main, "position:y", 6.0, 0.05).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_property(_main, "position:y", 0.0, 0.05).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	var col := _fx_color()
	var tex := PixelArt.make_texture(PixelArt.PUFF, {"h": col}, 2)
	for i in 6:
		var p := Sprite2D.new()
		p.texture = tex
		p.rotation = randf() * TAU
		var ang := randf() * TAU
		var dist := randf_range(18.0, 44.0)
		p.position = Vector2(cos(ang), sin(ang) * 0.6) * dist
		var pt := create_tween()
		pt.tween_property(p, "position:y", p.position.y - 14.0, 0.5)
		pt.parallel().tween_property(p, "modulate:a", 0.0, 0.5)
		pt.tween_callback(p.queue_free)
		add_child(p)

func _fx_color() -> Color:
	match resource_type:
		"wood":
			return Color("#4f8f52")
		"stone":
			return Color("#8d929a")
		"mineral":
			return Color("#9db2d6")
		"fiber":
			return Color("#5fbf8b")
		"leather":
			return Color("#b07d4f")
	return Color("#8d929a")

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