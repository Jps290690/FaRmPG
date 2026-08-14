extends CanvasLayer

const HOTBAR_SLOTS := 8
const SLOT_W := 96
const SLOT_H := 44

const TOOL_ORDER := ["axe", "metal_axe", "pickaxe", "metal_pickaxe", "sickle", "metal_sickle", "skinning_knife", "metal_knife"]

@onready var tool_label: Label = $Tool
@onready var inventory_label: Label = $Inventory
@onready var skills_label: Label = $Skills
@onready var progress_label: Label = $Progress
@onready var message_label: Label = $Message

var _msg_timer: Timer
var _hotbar_order: Array[String] = []
var _slot_buttons: Array[Button] = []
var _inventory_panel: PanelContainer
var _weight_bar: ProgressBar
var _weight_label: Label
var _weight_fill: StyleBoxFlat
var _item_list: VBoxContainer
var _craft_panel: PanelContainer
var _craft_title: Label
var _craft_list: VBoxContainer
var _craft_station_id := ""
var _merchant_panel: PanelContainer
var _merchant_title: Label
var _merchant_list: VBoxContainer
var _hp_bar: ProgressBar
var _hp_label: Label
var _death_panel: PanelContainer

func _ready() -> void:
	_msg_timer = Timer.new()
	_msg_timer.one_shot = true
	_msg_timer.wait_time = 3.0
	_msg_timer.timeout.connect(_clear_message)
	add_child(_msg_timer)
	_build_hotbar()
	_build_inventory_panel()
	_build_crafting_panel()
	_build_merchant_panel()
	_build_hp_bar()
	_build_death_panel()
	refresh_tool("")
	refresh_inventory()
	refresh_skills()
	set_hp(Player.MAX_HP)
	var player := get_tree().get_first_node_in_group("player")
	if player:
		set_equipped(player.equipped)
	progress_label.visible = false
	message_label.visible = false

func _build_hotbar() -> void:
	var root := Control.new()
	root.name = "Hotbar"
	root.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	root.offset_top = -52.0
	root.offset_bottom = -8.0
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center)
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.09, 0.11, 0.12, 0.85)
	sb.border_color = Color(1, 1, 1, 0.18)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 6
	sb.content_margin_right = 6
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	panel.add_theme_stylebox_override("panel", sb)
	center.add_child(panel)
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 4)
	panel.add_child(hbox)
	for i in HOTBAR_SLOTS:
		var b := Button.new()
		b.custom_minimum_size = Vector2(SLOT_W, SLOT_H)
		b.toggle_mode = true
		b.add_theme_font_size_override("font_size", 13)
		var idx := i
		b.pressed.connect(_on_slot_pressed.bind(idx))
		hbox.add_child(b)
		_slot_buttons.append(b)

func _build_inventory_panel() -> void:
	var panel := PanelContainer.new()
	panel.name = "InventoryPanel"
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(380, 0)
	panel.visible = false
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.09, 0.11, 0.12, 0.94)
	sb.border_color = Color(1, 1, 1, 0.18)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", sb)
	add_child(panel)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "Inventario — B para cerrar"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	vbox.add_child(title)

	var wh := HBoxContainer.new()
	wh.add_theme_constant_override("separation", 10)
	vbox.add_child(wh)
	var wl := Label.new()
	wl.text = "Peso"
	wl.custom_minimum_size = Vector2(44, 0)
	wl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	wh.add_child(wl)
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(190, 18)
	bar.show_percentage = false
	bar.max_value = float(Inventory.MAX_WEIGHT)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0, 0, 0, 0.5)
	bg.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("background", bg)
	var fill := StyleBoxFlat.new()
	fill.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("fill", fill)
	wh.add_child(bar)
	var wv := Label.new()
	wv.custom_minimum_size = Vector2(84, 0)
	wv.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	wv.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	wh.add_child(wv)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	var list := VBoxContainer.new()
	list.name = "ItemList"
	list.add_theme_constant_override("separation", 2)
	vbox.add_child(list)

	_inventory_panel = panel
	_weight_bar = bar
	_weight_label = wv
	_weight_fill = fill
	_item_list = list

func toggle_inventory() -> void:
	refresh_inventory()
	_inventory_panel.visible = not _inventory_panel.visible

func set_equipped(id: String) -> void:
	refresh_tool(id)
	refresh_hotbar()

func hotbar_id_at(index: int) -> String:
	if index >= 0 and index < _hotbar_order.size():
		return _hotbar_order[index]
	return ""

func _on_slot_pressed(index: int) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	player.select_slot(index)

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
	if GameItems.is_weapon_item(id):
		tool_label.text = "Equipado: %s" % info.get("name", id)
		return
	var cur = player.inventory.get_durability(id)
	var max_d := GameItems.max_durability(id)
	tool_label.text = "Equipado: %s  %d/%d" % [info.get("name", id), int(cur), int(max_d)]

func refresh_inventory() -> void:
	if not is_node_ready():
		return
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	var snap: Dictionary = player.inventory.snapshot()
	var w: float = player.inventory.total_weight()

	var parts: Array[String] = []
	for id: String in snap:
		if GameItems.is_tool_item(id):
			continue
		parts.append("%s x%d" % [GameItems.name_of(id), int(snap[id].get("count", 0))])
	inventory_label.text = "Inventario (%d/%d kg)  " % [int(w), int(Inventory.MAX_WEIGHT)]
	inventory_label.text += " · ".join(parts) if not parts.is_empty() else "vacío"

	_weight_bar.value = w
	_weight_label.text = "%.1f / %.0f kg" % [w, float(Inventory.MAX_WEIGHT)]
	_update_weight_color(w)

	for c in _item_list.get_children():
		_item_list.remove_child(c)
		c.queue_free()
	if snap.is_empty():
		var empty := Label.new()
		empty.text = "Vacío"
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.modulate.a = 0.6
		_item_list.add_child(empty)
		return
	for id: String in snap:
		var row := Label.new()
		var s: Dictionary = snap[id]
		var iw: float = GameItems.info(id).get("weight", 0.0)
		if GameItems.is_tool_item(id):
			row.text = "%s   %d/%d   (%.1f kg)" % [GameItems.name_of(id), int(s.get("durability", 0)), int(GameItems.max_durability(id)), iw]
		else:
			row.text = "%s x%d   (%.1f kg)" % [GameItems.name_of(id), int(s.get("count", 0)), iw * int(s.get("count", 0))]
		_item_list.add_child(row)

func _update_weight_color(w: float) -> void:
	var ratio := w / Inventory.MAX_WEIGHT
	if ratio > 0.9:
		_weight_fill.bg_color = Color(0.85, 0.25, 0.2, 1)
	elif ratio > 0.7:
		_weight_fill.bg_color = Color(0.9, 0.65, 0.2, 1)
	else:
		_weight_fill.bg_color = Color(0.3, 0.75, 0.35, 1)

func refresh_hotbar() -> void:
	if not is_node_ready():
		return
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	var snap: Dictionary = player.inventory.snapshot()
	_hotbar_order = _hotbar_from_snapshot(snap)
	var selected: String = player.equipped
	for i in HOTBAR_SLOTS:
		var b: Button = _slot_buttons[i]
		if i < _hotbar_order.size():
			var id: String = _hotbar_order[i]
			var s: Dictionary = snap[id]
			var text := ""
			if GameItems.is_tool_item(id):
				text = "%s %d" % [GameItems.short_name(id), int(s.get("durability", 0))]
			else:
				text = "%s x%d" % [GameItems.short_name(id), int(s.get("count", 0))]
			b.disabled = false
			b.tooltip_text = GameItems.name_of(id)
			b.text = text
			b.button_pressed = (id == selected)
		else:
			b.disabled = true
			b.tooltip_text = ""
			b.text = ""
			b.button_pressed = false

func _hotbar_from_snapshot(snap: Dictionary) -> Array[String]:
	var order: Array[String] = []
	for t in TOOL_ORDER:
		if snap.has(t):
			order.append(t)
	for id: String in snap:
		if not GameItems.is_tool_item(id) and id not in order:
			order.append(id)
	return order

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

func _build_crafting_panel() -> void:
	var panel := PanelContainer.new()
	panel.name = "CraftPanel"
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(420, 0)
	panel.visible = false
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.09, 0.11, 0.12, 0.94)
	sb.border_color = Color(1, 1, 1, 0.18)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", sb)
	add_child(panel)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	var title := Label.new()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	title.text = ""
	vbox.add_child(title)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	var list := VBoxContainer.new()
	list.name = "CraftList"
	list.add_theme_constant_override("separation", 6)
	vbox.add_child(list)

	_craft_panel = panel
	_craft_title = title
	_craft_list = list

func open_crafting(station_id: String, station_name: String) -> void:
	_craft_station_id = station_id
	_craft_title.text = "%s — E para cerrar" % station_name
	refresh_crafting()
	_craft_panel.visible = true

func close_crafting() -> void:
	_craft_panel.visible = false
	_craft_station_id = ""

func craft_panel_open() -> bool:
	return _craft_panel != null and _craft_panel.visible

func craft_station_id() -> String:
	return _craft_station_id

func refresh_crafting() -> void:
	if not is_node_ready():
		return
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	for c in _craft_list.get_children():
		_craft_list.remove_child(c)
		c.queue_free()
	if _craft_station_id.is_empty():
		return
	for recipe_id: String in Recipes.recipes_for_station(_craft_station_id):
		var recipe: Dictionary = Recipes.recipe_info(recipe_id)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		_craft_list.add_child(row)
		var label := Label.new()
		label.custom_minimum_size = Vector2(300, 0)
		label.text = "%s\n  %s" % [recipe.get("name", recipe_id), Recipes.inputs_text(recipe.get("inputs", {}))]
		row.add_child(label)
		var btn := Button.new()
		btn.text = "Craftear"
		var rid := recipe_id
		btn.pressed.connect(_on_craft_pressed.bind(rid))
		row.add_child(btn)
		_refresh_craft_button(btn, player, recipe)

func _refresh_craft_button(btn: Button, player: Node, recipe: Dictionary) -> void:
	var locked := Recipes.skill_locked(player.skills, recipe)
	var afford := Recipes.can_afford(player.inventory, recipe.get("inputs", {}))
	btn.disabled = locked or not afford
	var tip := ""
	if locked:
		tip = "Requiere %s L%d" % [Skills.SKILLS.get(String(recipe.get("skill", "")), {}).get("name", ""), int(recipe.get("level", 0))]
	elif not afford:
		tip = "Faltan materiales"
	btn.tooltip_text = tip

func _on_craft_pressed(recipe_id: String) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.craft(recipe_id)

func _build_merchant_panel() -> void:
	var panel := PanelContainer.new()
	panel.name = "MerchantPanel"
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(460, 0)
	panel.visible = false
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.09, 0.11, 0.12, 0.94)
	sb.border_color = Color(1, 0.85, 0.4, 0.25)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", sb)
	add_child(panel)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	var title := Label.new()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	title.text = ""
	vbox.add_child(title)

	var gold := Label.new()
	gold.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gold.add_theme_font_size_override("font_size", 14)
	gold.add_theme_color_override("font_color", Color(1, 0.9, 0.4, 1))
	gold.text = ""
	vbox.add_child(gold)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	var list := VBoxContainer.new()
	list.name = "MerchantList"
	list.add_theme_constant_override("separation", 6)
	vbox.add_child(list)

	_merchant_panel = panel
	_merchant_title = title
	_merchant_list = list

func open_merchant() -> void:
	_merchant_title.text = "Comerciante — E para cerrar"
	refresh_merchant()
	_merchant_panel.visible = true

func close_merchant() -> void:
	_merchant_panel.visible = false

func merchant_open() -> bool:
	return _merchant_panel != null and _merchant_panel.visible

func refresh_merchant() -> void:
	if not is_node_ready():
		return
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	var economy: Economy = player.economy
	var gold_label: Label = _merchant_title.get_parent().get_child(1)
	gold_label.text = "Oro: %d" % player.inventory.count("gold")
	for c in _merchant_list.get_children():
		_merchant_list.remove_child(c)
		c.queue_free()
	for id: String in economy.BASE_PRICES:
		var buy := economy.buy_price(id)
		var sell := economy.sell_price(id)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		_merchant_list.add_child(row)
		var label := Label.new()
		label.custom_minimum_size = Vector2(210, 0)
		label.text = "%s\n  Compra %dg · Venta %dg" % [GameItems.name_of(id), buy, sell]
		row.add_child(label)
		var stock := Label.new()
		stock.custom_minimum_size = Vector2(70, 0)
		stock.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		stock.text = "x%d" % player.inventory.count(id)
		row.add_child(stock)
		var buy_btn := Button.new()
		buy_btn.text = "Comprar x1"
		buy_btn.disabled = player.inventory.count("gold") < buy or not player.inventory.can_add(id, 1)
		buy_btn.tooltip_text = "Falta oro" if player.inventory.count("gold") < buy else "Inventario lleno"
		var bid := id
		buy_btn.pressed.connect(_on_merchant_buy.bind(bid))
		row.add_child(buy_btn)
		var sell_btn := Button.new()
		sell_btn.text = "Vender x1"
		sell_btn.disabled = not player.inventory.has_item(id)
		sell_btn.tooltip_text = "No tenés este recurso"
		var sid := id
		sell_btn.pressed.connect(_on_merchant_sell.bind(sid))
		row.add_child(sell_btn)

func _on_merchant_buy(id: String) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.merchant_buy(id)

func _on_merchant_sell(id: String) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.merchant_sell(id)

func _build_hp_bar() -> void:
	var root := Control.new()
	root.name = "HpRoot"
	root.set_anchors_preset(Control.PRESET_CENTER_TOP)
	root.offset_top = 8.0
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center)
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	center.add_child(hbox)
	var label := Label.new()
	label.text = "Vida"
	label.add_theme_color_override("font_color", Color(1, 1, 1, 0.95))
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	label.add_theme_constant_override("outline_size", 3)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(label)
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(220, 18)
	bar.show_percentage = false
	bar.max_value = Player.MAX_HP
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0, 0, 0, 0.5)
	bg.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("background", bg)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.85, 0.25, 0.2, 1)
	fill.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("fill", fill)
	hbox.add_child(bar)
	var val := Label.new()
	val.custom_minimum_size = Vector2(90, 0)
	val.text = "100/100"
	val.add_theme_color_override("font_color", Color(1, 1, 1, 0.95))
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hbox.add_child(val)
	_hp_bar = bar
	_hp_label = val

func set_hp(hp: float) -> void:
	if not is_node_ready():
		return
	_hp_bar.value = hp
	_hp_label.text = "%.0f/%.0f" % [hp, Player.MAX_HP]

func _build_death_panel() -> void:
	var panel := PanelContainer.new()
	panel.name = "DeathPanel"
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(380, 0)
	panel.visible = false
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.05, 0.05, 0.94)
	sb.border_color = Color(1, 0.4, 0.3, 0.5)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 24
	sb.content_margin_right = 24
	sb.content_margin_top = 18
	sb.content_margin_bottom = 18
	panel.add_theme_stylebox_override("panel", sb)
	add_child(panel)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)
	var title := Label.new()
	title.text = "Has muerto"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(1, 0.5, 0.4, 1))
	vbox.add_child(title)
	var sub := Label.new()
	sub.text = "Perdiste todo tu inventario."
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(sub)
	var hint := Label.new()
	hint.text = "Presioná R para reaparecer en la base"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.8))
	vbox.add_child(hint)
	_death_panel = panel

func show_death() -> void:
	_death_panel.visible = true

func hide_death() -> void:
	_death_panel.visible = false

func message(text: String) -> void:
	message_label.text = text
	message_label.visible = true
	_msg_timer.start()

func _clear_message() -> void:
	message_label.visible = false
