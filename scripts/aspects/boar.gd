class_name BoarAspect
extends Aspect

# Caza mayor: rara, huye al instante si te detecta, suelta mucho cuero.
const ZONE := Rect2(0, 576, 1536, 576)
const FLEE_RANGE := 260.0
const FLEE_SPEED := 190.0
const WANDER_SPEED := 80.0

var _wander_target := Vector2.ZERO
var _pause := 0.0
var _fleeing := false

func _init() -> void:
	max_hp = 40.0
	damage = 0.0
	detection_range = FLEE_RANGE
	speed = WANDER_SPEED
	loot = {"leather": 8}

func _build_body() -> void:
	var body := Node2D.new()
	body.name = "Body"
	add_child(body)
	_poly(body, PackedVector2Array([-18, 2, -6, -10, 8, -8, 16, 0, 10, 10, -10, 10]), Color("#8a5a3b"))
	_poly(body, PackedVector2Array([16, -2, 24, -6, 22, 2, 14, 2]), Color("#7a4c30"))
	_poly(body, PackedVector2Array([-8, -12, -2, -16, 4, -12, 2, -8, -6, -8]), Color("#6e4026"))

func take_damage(amount: float) -> void:
	super.take_damage(amount)
	if not dead:
		_fleeing = true

func _tick(delta: float) -> void:
	var p := _player()
	if p == null:
		return
	if p.dead:
		_fleeing = false
		return
	var d := global_position.distance_to(p.global_position)
	if not _fleeing and d < FLEE_RANGE:
		_fleeing = true
	if _fleeing:
		var dir := (global_position - p.global_position).normalized()
		var dest := global_position + dir * 400.0
		if not ZONE.has_point(dest):
			dest = ZONE.get_center()
		_move_toward(dest, delta, FLEE_SPEED)
		if d > FLEE_RANGE * 1.4:
			_fleeing = false
	else:
		_wander(delta)

func _wander(delta: float) -> void:
	if _pause > 0.0:
		_pause -= delta
		return
	if _wander_target == Vector2.ZERO or global_position.distance_to(_wander_target) < 10.0:
		_wander_target = _random_point()
		_pause = randf_range(1.5, 3.5)
		return
	_move_toward(_wander_target, delta)

func _random_point() -> Vector2:
	return Vector2(
		randf_range(ZONE.position.x + 90.0, ZONE.end.x - 90.0),
		randf_range(ZONE.position.y + 90.0, ZONE.end.y - 90.0)
	)

func calm() -> void:
	super.calm()
	_fleeing = false

func debug_state() -> String:
	return "Boar " + super.debug_state() + " fleeing=%s" % _fleeing
