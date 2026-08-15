class_name DryadAspect
extends Aspect

# Sigilosa y venenosa: camuflada entre los árboles de fibra; te sorprende si te
# acercás mucho y su veneno aplica DoT.
const ZONE := Rect2(1536, 576, 1536, 576)
const SURPRISE_RANGE := 110.0
const POISON_DPS := 3.0
const POISON_TIME := 5.0

var _revealed := false

func _init() -> void:
	max_hp = 60.0
	damage = 10.0
	detection_range = SURPRISE_RANGE
	attack_range = 55.0
	attack_cooldown = 1.3
	telegraph_time = 0.25
	speed = 90.0

func _build_body() -> void:
	_setup_body(PixelArt.SPRITES["DRYAD"])
	_body.modulate = Color(1, 1, 1, 0.2)

func _tick(delta: float) -> void:
	var p := _player()
	if p == null:
		return
	var d := global_position.distance_to(p.global_position)
	if not _revealed and d < SURPRISE_RANGE:
		_revealed = true
		hostile = true
		_body.modulate = Color.WHITE
		p.notify("¡Una Dríade te sorprendió!")
	if hostile:
		# Si el jugador se aleja bastante, vuelve a camuflarse y se deshostiliza.
		if d > SURPRISE_RANGE * 1.8 and not ZONE.has_point(p.global_position):
			_revealed = false
			hostile = false
			_body.modulate = Color(1, 1, 1, 0.2)
			return
		_move_toward(p.global_position, delta)
		_try_melee(delta)

func _attack_hit() -> void:
	super._attack_hit()
	var p := _player()
	if p and not p.dead and global_position.distance_to(p.global_position) <= attack_range + 10.0:
		p.apply_poison(POISON_DPS, POISON_TIME)

func _on_hurt() -> void:
	super._on_hurt()
	if not _revealed:
		_revealed = true
		_body.modulate = Color.WHITE

func calm() -> void:
	super.calm()
	_revealed = false
	_body.modulate = Color(1, 1, 1, 0.2)

func debug_state() -> String:
	return "Dryad " + super.debug_state() + " revealed=%s" % _revealed
