class_name Aspect
extends Node2D

signal died(aspect: Aspect)

@export var max_hp := 100.0
@export var damage := 15.0
@export var detection_range := 200.0
@export var attack_range := 55.0
@export var attack_cooldown := 1.2
@export var telegraph_time := 0.0
@export var speed := 50.0

var hp := 0.0
var dead := false
var hostile := false
var loot := {}

var _attack_cd := 0.0
var _telegraph_left := 0.0
var _flash_left := 0.0
var _body: Node2D
var _hp_bar: ProgressBar

func _ready() -> void:
	add_to_group("aspects")
	hp = max_hp
	_build_body()
	_body = get_node_or_null("Body")
	if _body == null:
		_body = self
	_build_hp_bar()

func _build_body() -> void:
	pass

func _build_hp_bar() -> void:
	_hp_bar = ProgressBar.new()
	_hp_bar.max_value = max_hp
	_hp_bar.value = max_hp
	_hp_bar.show_percentage = false
	_hp_bar.custom_minimum_size = Vector2(46, 6)
	_hp_bar.position = Vector2(-23, -56)
	_hp_bar.visible = false
	add_child(_hp_bar)

func _physics_process(delta: float) -> void:
	if dead:
		return
	var p := _player()
	if p != null and p.dead:
		return
	if _attack_cd > 0.0:
		_attack_cd -= delta
	if _telegraph_left > 0.0:
		_telegraph_left -= delta
		if _telegraph_left <= 0.0:
			_attack_hit()
	if _flash_left > 0.0:
		_flash_left -= delta
		if _flash_left <= 0.0:
			_set_flash(Color.WHITE)
	_hp_bar.visible = hp < max_hp
	_hp_bar.value = hp
	_tick(delta)
	# Zona segura: el jugador en su base no es reconocido ni atacado por nada.
	if p != null and p.in_base():
		calm()

func _tick(delta: float) -> void:
	pass

func take_damage(amount: float) -> void:
	if dead:
		return
	hp = maxf(0.0, hp - amount)
	_flash_left = 0.12
	_set_flash(Color(1.0, 0.45, 0.45, 1.0))
	_on_hurt()
	if hp <= 0.0:
		_die()

# Reacción al recibir daño (aggro, fuga, revelación...). Por defecto se enfada.
func _on_hurt() -> void:
	hostile = true

func _set_flash(c: Color) -> void:
	if _body:
		_body.modulate = c

func _die() -> void:
	dead = true
	_drop_loot()
	died.emit(self)
	queue_free()

func _drop_loot() -> void:
	var p := _player()
	if p == null or loot.is_empty():
		return
	for id: String in loot:
		var qty := int(loot[id])
		while qty > 0 and p.inventory.can_add(id, 1):
			p.inventory.add_item(id, 1)
			qty -= 1

# Intenta el ataque melee con telegrafía. Devuelve true si el ataque quedó
# "ocupando" al aspecto (en telegrafía o enfriamiento) — no debe moverse.
func _try_melee(delta: float) -> bool:
	if _attack_cd > 0.0 or _telegraph_left > 0.0:
		return true
	var p := _player()
	if p == null or p.in_base():
		return false
	if global_position.distance_to(p.global_position) > attack_range:
		return false
	_attack_cd = attack_cooldown
	if telegraph_time > 0.0:
		_telegraph_left = telegraph_time
		_on_telegraph_start()
		return true
	_attack_hit()
	return true

func _on_telegraph_start() -> void:
	pass

func _attack_hit() -> void:
	_on_telegraph_end()
	var p := _player()
	if p == null or p.dead or p.in_base():
		return
	if global_position.distance_to(p.global_position) <= attack_range + 10.0:
		p.take_damage(damage)

func _on_telegraph_end() -> void:
	pass

func _move_toward(pos: Vector2, delta: float, spd: float = -1.0) -> void:
	var s := speed if spd < 0.0 else spd
	global_position = global_position.move_toward(pos, s * delta)

# Apaga la agresión (usado cuando el jugador muere/respawnea). Cada aspecto
# resetea además su estado visual propio.
func calm() -> void:
	hostile = false
	_telegraph_left = 0.0
	_on_telegraph_end()

func _player() -> Player:
	return get_tree().get_first_node_in_group("player") as Player

func _poly(parent: Node2D, pts: PackedVector2Array, color: Color) -> void:
	var p := Polygon2D.new()
	p.polygon = pts
	p.color = color
	parent.add_child(p)

func debug_state() -> String:
	return "hp=%.0f/%.0f hostile=%s dead=%s pos=(%.0f,%.0f)" % [hp, max_hp, hostile, dead, global_position.x, global_position.y]
