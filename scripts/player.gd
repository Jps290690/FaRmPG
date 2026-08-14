extends CharacterBody2D

const SPEED := 220.0
const CLICK_EPSILON := 6.0
const GATHER_RANGE := 70.0

var has_target := false
var move_target := Vector2.ZERO

var inventory := Inventory.new()
var skills := Skills.new()
var equipped := "axe"

var _gathering := false
var _gather_node: ResourceNode = null
var _gather_tool := ""
var _gather_total := 1.0
var _gather_elapsed := 0.0

@onready var world: Node2D = get_parent()
@onready var hud: Node = world.get_node("HUD")
@onready var nodes_container: Node2D = world.get_node("ResourceNodes")

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
		move_target = get_global_mouse_position()
		has_target = true
		return
	if event.is_action_pressed("interact"):
		_try_gather()
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
	if not GameItems.is_tool_item(id):
		hud.message("Eso no es una herramienta.")
		return
	equipped = id
	hud.set_equipped(equipped)

func _physics_process(delta: float) -> void:
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
	if equipped != node.tool_required:
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

func debug_state() -> String:
	var lines := PackedStringArray()
	lines.append("inventory=%s" % inventory.debug_string())
	lines.append("skills=%s" % skills.debug_string())
	lines.append("equipped=%s" % equipped)
	lines.append("gathering=%s gather_node=%s" % [_gathering, _gather_node.get_path() if _gather_node else ""])
	return "\n".join(lines)
