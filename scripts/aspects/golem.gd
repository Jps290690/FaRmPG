class_name GolemAspect
extends Aspect

# Zona de agresión: la cantera (tx>=24, ty<18 en píxeles del mundo).
const ZONE := Rect2(1536, 0, 1536, 576)

var _core: Polygon2D
var _patrol_target := Vector2.ZERO
var _pause := 0.0

func _init() -> void:
	max_hp = 120.0
	damage = 40.0
	detection_range = 260.0
	attack_range = 70.0
	attack_cooldown = 2.4
	telegraph_time = 0.8
	speed = 38.0

func _build_body() -> void:
	_setup_body(PixelArt.SPRITES["GOLEM"])
	_core = Polygon2D.new()
	_core.polygon = PackedVector2Array([0, -4, 4, 0, 0, 4, -4, 0])
	_core.color = Color("#ffd84d")
	_core.position = Vector2(0, -14)
	_body.add_child(_core)

func _tick(delta: float) -> void:
	var p := _player()
	if p == null:
		return
	if not hostile and ZONE.has_point(p.global_position) and global_position.distance_to(p.global_position) < detection_range:
		hostile = true
	if hostile:
		if global_position.distance_to(p.global_position) > attack_range:
			_move_toward(p.global_position, delta)
		else:
			_try_melee(delta)
		if not ZONE.has_point(p.global_position) and global_position.distance_to(p.global_position) > detection_range * 1.4:
			hostile = false
	else:
		_patrol(delta)

func _on_telegraph_start() -> void:
	if _core:
		_core.color = Color(1.0, 0.95, 0.6, 1.0)
		_core.scale = Vector2(1.7, 1.7)

func _on_telegraph_end() -> void:
	if _core:
		_core.color = Color("#ffd84d")
		_core.scale = Vector2.ONE

func _patrol(delta: float) -> void:
	if _pause > 0.0:
		_pause -= delta
		return
	if _patrol_target == Vector2.ZERO or global_position.distance_to(_patrol_target) < 8.0:
		_patrol_target = _random_point()
		_pause = randf_range(2.0, 4.0)
		return
	_move_toward(_patrol_target, delta)

func _random_point() -> Vector2:
	return Vector2(
		randf_range(ZONE.position.x + 90.0, ZONE.end.x - 90.0),
		randf_range(ZONE.position.y + 90.0, ZONE.end.y - 90.0)
	)

func calm() -> void:
	super.calm()
	if _core:
		_core.color = Color("#ffd84d")
		_core.scale = Vector2.ONE

func debug_state() -> String:
	return "Golem " + super.debug_state() + " telegraph_left=%.2f" % _telegraph_left
