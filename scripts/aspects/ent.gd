class_name EntAspect
extends Aspect

# Zona de agresión: el bosque (tx<24, ty<18 en píxeles del mundo).
const ZONE := Rect2(0, 0, 1536, 576)

const CHASE_SPEED := 110.0
const PATROL_SPEED := 60.0

var _patrol_target := Vector2.ZERO
var _pause := 0.0
var _calm_left := 0.0
var _eyes: Node2D

func _init() -> void:
	max_hp = 80.0
	damage = 15.0
	detection_range = 240.0
	attack_range = 55.0
	attack_cooldown = 1.6
	telegraph_time = 0.35
	speed = PATROL_SPEED

func _build_body() -> void:
	_setup_body(PixelArt.SPRITES["ENT"])
	_eyes = PixelArt.make_sprite_centered(_body, PixelArt.SPRITES["EYES"], PixelArt.PAL, 2)
	_eyes.visible = false
	_eyes.position = Vector2(0, -25)

func _tick(delta: float) -> void:
	var p := _player()
	if p == null:
		return
	if not hostile:
		# Se enfada si el jugador taló/cosechó cerca hace poco.
		if p.time_since_gather() < 2.0 and global_position.distance_to(p.last_gather_pos()) < detection_range:
			hostile = true
			_calm_left = 3.0
			_eyes.visible = true
			p.notify("¡El Ent se enfadó por talar cerca!")
	if hostile:
		if ZONE.has_point(p.global_position):
			_calm_left = 3.0
		else:
			_calm_left -= delta
			if _calm_left <= 0.0:
				hostile = false
				_eyes.visible = false
		_move_toward(p.global_position, delta, CHASE_SPEED)
		_try_melee(delta)
	else:
		_patrol(delta)

func _patrol(delta: float) -> void:
	if _pause > 0.0:
		_pause -= delta
		return
	if _patrol_target == Vector2.ZERO or global_position.distance_to(_patrol_target) < 8.0:
		_patrol_target = _random_point()
		_pause = randf_range(1.0, 3.0)
		return
	_move_toward(_patrol_target, delta)

func _random_point() -> Vector2:
	return Vector2(
		randf_range(ZONE.position.x + 90.0, ZONE.end.x - 90.0),
		randf_range(ZONE.position.y + 90.0, ZONE.end.y - 90.0)
	)

func _on_hurt() -> void:
	super._on_hurt()
	_calm_left = 3.0
	_eyes.visible = true

func calm() -> void:
	super.calm()
	_calm_left = 0.0
	_eyes.visible = false

func debug_state() -> String:
	return "Ent " + super.debug_state() + " calm_left=%.1f" % _calm_left
