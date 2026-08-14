class_name Player
extends CharacterBody2D

const SPEED := 220.0
const CLICK_EPSILON := 6.0
const GATHER_RANGE := 70.0
const STATION_RANGE := 95.0
const MAX_HP := 100.0
const BASE_PUNCH := 5.0
const ATTACK_CD := 0.6
const MELEE_RANGE := 65.0
const BASE_POS := Vector2(1536, 576)

var has_target := false
var move_target := Vector2.ZERO

var inventory := Inventory.new()
var skills := Skills.new()
var equipped := "axe"

var hp := MAX_HP
var dead := false

var _gathering := false
var _gather_node: ResourceNode = null
var _gather_tool := ""
var _gather_total := 1.0
var _gather_elapsed := 0.0

var _attack_cd := 0.0
var _poison_dps := 0.0
var _poison_left := 0.0
var _poison_timer := 0.0
var _last_gather_pos := Vector2.ZERO
var _last_gather_time := -999.0

@onready var world: Node2D = get_parent()
@onready var hud: Node = world.get_node("HUD")
@onready var nodes_container: Node2D = world.get_node("ResourceNodes")
@onready var stations_container: Node2D = world.get_node("Stations")
@onready var sprite: Polygon2D = $Sprite

func _ready() -> void:
	add_to_group("player")
	inventory.changed.connect(hud.refresh_inventory)
	inventory.changed.connect(hud.refresh_hotbar)
	skills.changed.connect(hud.refresh_skills)
	_starter_tools()

func _starter_tools() -> void:
	inventory.add_item("axe")
	inventory.add_item("pickaxe")
	inventory.add_item("sickle")
	inventory.add_item("skinning_knife")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("move_click"):
		var enemy := _aspect_at(get_global_mouse_position(), MELEE_RANGE + 16.0)
		if enemy != null:
			_attack_target(enemy)
			return
		move_target = get_global_mouse_position()
		has_target = true
		return
	if event.is_action_pressed("interact"):
		_try_interact()
		return
	if event.is_action_pressed("attack"):
		_try_attack()
		return
	if event.is_action_pressed("respawn"):
		if dead:
			_respawn()
		return
	if event.is_action_pressed("toggle_inventory"):
		hud.toggle_inventory()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var kce: InputEventKey = event
		var kc: int = kce.physical_keycode
		if kc >= KEY_1 and kc <= KEY_8:
			select_slot(kc - KEY_1)

func select_slot(index: int) -> void:
	var id: String = hud.hotbar_id_at(index)
	if id.is_empty():
		return
	if not GameItems.is_tool_item(id) and not GameItems.is_weapon_item(id):
		hud.message("Eso no se puede equipar.")
		return
	equipped = id
	hud.set_equipped(equipped)

func _physics_process(delta: float) -> void:
	if dead:
		velocity = Vector2.ZERO
		return
	if _attack_cd > 0.0:
		_attack_cd -= delta
	_tick_poison(delta)
	if _gathering:
		velocity = Vector2.ZERO
		_gather_elapsed += delta
		hud.show_progress(_gather_elapsed / _gather_total)
		if _gather_elapsed >= _gather_total:
			_complete_gather()
		return

	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	if input_dir != Vector2.ZERO:
		has_target = false
		velocity = input_dir * SPEED
	else:
		if has_target:
			var to_target := move_target - global_position
			if to_target.length() > CLICK_EPSILON:
				velocity = to_target.normalized() * SPEED
			else:
				has_target = false
				velocity = Vector2.ZERO
		else:
			velocity = Vector2.ZERO

	move_and_slide()

func _tick_poison(delta: float) -> void:
	if _poison_left <= 0.0:
		return
	_poison_timer += delta
	while _poison_timer >= 1.0:
		_poison_timer -= 1.0
		_poison_left -= 1.0
		_receive_damage(_poison_dps)
		if _poison_left <= 0.0:
			break
	sprite.modulate = Color(0.7, 1.0, 0.7, 1.0) if _poison_left > 0.0 else Color.WHITE

func take_damage(amount: float) -> void:
	if dead:
		return
	_receive_damage(amount)

func _receive_damage(amount: float) -> void:
	var dmg := amount
	if inventory.has_item("chestplate"):
		dmg = maxf(1.0, dmg - GameItems.armor_value("chestplate"))
	hp = maxf(0.0, hp - dmg)
	hud.set_hp(hp)
	if hp <= 0.0:
		_die()

func apply_poison(dps: float, seconds: float) -> void:
	if dead:
		return
	_poison_dps = dps
	_poison_left = seconds
	_poison_timer = 0.0

func _die() -> void:
	dead = true
	_gathering = false
	_poison_dps = 0.0
	_poison_left = 0.0
	_poison_timer = 0.0
	sprite.modulate = Color.WHITE
	for a in get_tree().get_nodes_in_group("aspects"):
		a.calm()
	has_target = false
	velocity = Vector2.ZERO
	hud.hide_progress()
	inventory.clear()
	equipped = ""
	hud.set_equipped(equipped)
	hud.show_death()
	hud.message("Has muerto. Perdiste todo lo que llevabas.")

func _respawn() -> void:
	dead = false
	hp = MAX_HP
	global_position = BASE_POS
	has_target = false
	_gathering = false
	_poison_dps = 0.0
	_poison_left = 0.0
	_poison_timer = 0.0
	sprite.modulate = Color.WHITE
	for a in get_tree().get_nodes_in_group("aspects"):
		a.calm()
	hud.set_hp(hp)
	hud.hide_death()
	inventory.clear()
	_starter_tools()
	equipped = "axe"
	hud.set_equipped(equipped)
	hud.message("Reapareciste en la base.")

func _try_attack() -> void:
	if dead or _gathering or _attack_cd > 0.0:
		return
	var enemy := _nearest_enemy(MELEE_RANGE)
	if enemy == null:
		hud.message("No hay enemigos a la distancia de ataque.")
		_attack_cd = 0.25
		return
	_attack_target(enemy)

func _attack_target(enemy: Aspect) -> void:
	if _attack_cd > 0.0:
		return
	_attack_cd = ATTACK_CD
	enemy.take_damage(_weapon_damage())

func _weapon_damage() -> float:
	if GameItems.is_weapon_item(equipped):
		return GameItems.weapon_damage(equipped)
	return BASE_PUNCH

func _nearest_enemy(max_d: float) -> Aspect:
	var best: Aspect = null
	var best_d := max_d
	for node in get_tree().get_nodes_in_group("aspects"):
		var a := node as Aspect
		if a == null or a.dead:
			continue
		var d := global_position.distance_to(a.global_position)
		if d < best_d:
			best_d = d
			best = a
	return best

func _aspect_at(pos: Vector2, max_d: float) -> Aspect:
	var best: Aspect = null
	var best_d := max_d
	for node in get_tree().get_nodes_in_group("aspects"):
		var a := node as Aspect
		if a == null or a.dead:
			continue
		var d := a.global_position.distance_to(pos)
		if d < best_d:
			best_d = d
			best = a
	return best

func notify(text: String) -> void:
	hud.message(text)

func last_gather_pos() -> Vector2:
	return _last_gather_pos

func time_since_gather() -> float:
	return (Time.get_ticks_msec() * 0.001) - _last_gather_time

# Debug: simula que el jugador recolectó en `pos` ahora mismo (para verificar al Ent).
# Acepta Vector2 o String "x,y" / "Vector2(x,y)" (el puente MCP pasa args como String).
func debug_emulate_gather(pos: Variant) -> void:
	var target: Vector2
	if pos is String:
		var parts: PackedStringArray = String(pos).replace("Vector2(", "").replace(")", "").split(",", false)
		target = Vector2(float(parts[0]), float(parts[1]))
	else:
		target = pos
	_last_gather_pos = target
	_last_gather_time = Time.get_ticks_msec() * 0.001

func _try_interact() -> void:
	if hud.craft_panel_open():
		hud.close_crafting()
		return
	var station := _nearest_station()
	if station == null:
		_try_gather()
		return
	if not station.built:
		_build_station(station)
		return
	hud.open_crafting(station.station_id, Recipes.station_info(station.station_id).get("name", station.station_id))

func _nearest_station() -> Station:
	var best: Station = null
	var best_d := STATION_RANGE
	for child in stations_container.get_children():
		var s := child as Station
		if s == null:
			continue
		var d := global_position.distance_to(s.global_position)
		if d < best_d:
			best_d = d
			best = s
	return best

func _build_station(station: Station) -> void:
	var cost: Dictionary = station.build_cost()
	if skills.level(String(cost.get("skill", ""))) < int(cost.get("level", 0)):
		hud.message("Requiere %s L%d." % [_skill_name(String(cost.get("skill", ""))), int(cost.get("level", 0))])
		return
	if not Recipes.can_afford(inventory, cost.get("inputs", {})):
		hud.message("Faltan materiales: %s." % Recipes.inputs_text(cost.get("inputs", {})))
		return
	for id: String in cost.get("inputs", {}):
		inventory.remove_item(id, int(cost["inputs"][id]))
	station.build()
	hud.message("¡Construiste %s!" % Recipes.station_info(station.station_id).get("name", station.station_id))
	_check_meta()

func craft(recipe_id: String) -> void:
	if not hud.craft_panel_open():
		return
	var station_id: String = hud.craft_station_id()
	var recipe: Dictionary = Recipes.recipe_info(recipe_id)
	if recipe.is_empty() or recipe.get("station", "") != station_id:
		return
	if Recipes.skill_locked(skills, recipe):
		hud.message("Requiere %s L%d." % [_skill_name(String(recipe.get("skill", ""))), int(recipe.get("level", 0))])
		hud.refresh_crafting()
		return
	if not Recipes.can_afford(inventory, recipe.get("inputs", {})):
		hud.message("Faltan materiales: %s." % Recipes.inputs_text(recipe.get("inputs", {})))
		hud.refresh_crafting()
		return
	if inventory.total_weight() + Recipes.net_weight_change(recipe) > Inventory.MAX_WEIGHT + 0.001:
		hud.message("Inventario lleno.")
		hud.refresh_crafting()
		return
	for id: String in recipe.get("inputs", {}):
		inventory.remove_item(id, int(recipe["inputs"][id]))
	var replaced := String(recipe.get("replaces", ""))
	if not replaced.is_empty() and inventory.has_item(replaced):
		inventory.remove_item(replaced, 1)
	for id: String in recipe.get("outputs", {}):
		inventory.add_item(id, int(recipe["outputs"][id]))
	hud.message("¡Crafteaste %s!" % recipe.get("name", recipe_id))
	hud.refresh_crafting()
	_check_meta()

func _skill_name(id: String) -> String:
	return Skills.SKILLS.get(id, {}).get("name", id)

func debug_add(item: String, qty: int = 1) -> void:
	inventory.add_item(item, qty)

func debug_remove(item: String, qty: int = 1) -> void:
	inventory.remove_item(item, qty)

func debug_skill(skill: String, xp: int) -> void:
	skills.add_xp(skill, xp)

func _check_meta() -> void:
	var all_built := true
	for child in stations_container.get_children():
		var s := child as Station
		if s == null or not s.built:
			all_built = false
			break
	var t1_done := true
	for item: String in Recipes.T1_SET:
		if not inventory.has_item(item):
			t1_done = false
			break
	if all_built and t1_done:
		hud.message("¡Objetivo del POC cumplido! Set T1 + 4 estaciones construidas.")

func _try_gather() -> void:
	if _gathering:
		return
	var node := _nearest_node()
	if node == null:
		hud.message("No hay recurso cerca.")
		return
	if equipped.is_empty():
		hud.message("Equipá una herramienta (hotbar 1-8).")
		return
	if GameItems.info(equipped).get("harvest", "") != node.resource_type:
		hud.message("Necesitás %s equipado." % GameItems.name_of(node.tool_required))
		return
	if inventory.get_durability(equipped) <= 0.0:
		hud.message("Tu %s está rota." % GameItems.name_of(equipped))
		return
	_gathering = true
	_gather_node = node
	_gather_tool = equipped
	_gather_total = node.gather_time * skills.speed_multiplier(node.skill)
	_gather_elapsed = 0.0
	has_target = false
	velocity = Vector2.ZERO

func _nearest_node() -> ResourceNode:
	var best: ResourceNode = null
	var best_d := GATHER_RANGE
	for child in nodes_container.get_children():
		var node := child as ResourceNode
		if node == null or not node.harvestable or node.amount <= 0:
			continue
		var d := global_position.distance_to(node.global_position)
		if d < best_d:
			best_d = d
			best = node
	return best

func _complete_gather() -> void:
	var node: ResourceNode = _gather_node
	_gathering = false
	_gather_node = null
	hud.hide_progress()

	if node == null or not is_instance_valid(node):
		return
	if node.amount <= 0:
		return

	var yield_qty: int = node.base_yield + skills.yield_bonus(node.skill)
	if inventory.can_add(node.resource_type, yield_qty):
		inventory.add_item(node.resource_type, yield_qty)
	else:
		hud.message("Inventario lleno.")
		return

	skills.add_xp(node.skill, Skills.XP_PER_GATHER)
	var still_ok := inventory.use_tool(_gather_tool)
	hud.refresh_tool(equipped)
	if not still_ok:
		equipped = ""
		hud.set_equipped(equipped)
		hud.message("Tu %s se rompió." % GameItems.name_of(_gather_tool))

	node.harvest_success()
	_last_gather_pos = node.global_position
	_last_gather_time = Time.get_ticks_msec() * 0.001

func debug_state() -> String:
	var lines := PackedStringArray()
	lines.append("hp=%.0f/%.0f dead=%s" % [hp, MAX_HP, dead])
	lines.append("inventory=%s" % inventory.debug_string())
	lines.append("skills=%s" % skills.debug_string())
	lines.append("equipped=%s" % equipped)
	lines.append("attack_cd=%.2f poison_left=%.1f" % [_attack_cd, _poison_left])
	lines.append("gathering=%s gather_node=%s" % [_gathering, _gather_node.get_path() if _gather_node else ""])
	var stations := PackedStringArray()
	for child in stations_container.get_children():
		var s := child as Station
		if s:
			stations.append(s.debug_state())
	lines.append("stations=[%s]" % ", ".join(stations))
	return "\n".join(lines)
