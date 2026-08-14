extends CanvasLayer

@onready var tool_label: Label = $Tool
@onready var inventory_label: Label = $Inventory
@onready var skills_label: Label = $Skills
@onready var progress_label: Label = $Progress
@onready var message_label: Label = $Message

var _msg_timer: Timer

func _ready() -> void:
	_msg_timer = Timer.new()
	_msg_timer.one_shot = true
	_msg_timer.wait_time = 3.0
	_msg_timer.timeout.connect(_clear_message)
	add_child(_msg_timer)
	refresh_tool("")
	refresh_inventory()
	refresh_skills()
	progress_label.visible = false
	message_label.visible = false

func refresh_tool(id: String) -> void:
	if not is_node_ready():
		return
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	if id.is_empty():
		tool_label.text = "Herramienta: —"
		return
	var info := GameItems.info(id)
	var cur = player.inventory.get_durability(id)
	var max_d := GameItems.max_durability(id)
	tool_label.text = "%s  %d/%d" % [info.get("name", id), int(cur), int(max_d)]

func refresh_inventory() -> void:
	if not is_node_ready():
		return
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	var parts: Array[String] = []
	var snap: Dictionary = player.inventory.snapshot()
	for id: String in snap:
		if GameItems.is_tool_item(id):
			continue
		parts.append("%s x%d" % [GameItems.name_of(id), int(snap[id].get("count", 0))])
	inventory_label.text = "Inventario (%d/%d kg)  " % [int(player.inventory.total_weight()), int(Inventory.MAX_WEIGHT)]
	inventory_label.text += " · ".join(parts) if not parts.is_empty() else "vacío"

func refresh_skills() -> void:
	if not is_node_ready():
		return
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	var parts: Array[String] = []
	for s in player.skills.summary():
		parts.append("%s L%d" % [s.name, s.level])
	skills_label.text = " · ".join(parts)

func show_progress(ratio: float) -> void:
	progress_label.visible = true
	progress_label.text = "Recolectando… %d%%" % int(clampf(ratio, 0.0, 1.0) * 100.0)

func hide_progress() -> void:
	progress_label.visible = false

func message(text: String) -> void:
	message_label.text = text
	message_label.visible = true
	_msg_timer.start()

func _clear_message() -> void:
	message_label.visible = false
