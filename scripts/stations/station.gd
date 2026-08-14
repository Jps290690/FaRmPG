class_name Station
extends Node2D

@export var station_id := "lumber_workbench"

var built := false

var _pad: Polygon2D
var _name_label: Label
var _cost_label: Label

func _ready() -> void:
	add_to_group("stations")
	_build_visuals()

func _build_visuals() -> void:
	var info := Recipes.station_info(station_id)
	var color := Color(info.get("color", "#888888"))
	var pad := Polygon2D.new()
	pad.name = "Pad"
	pad.polygon = PackedVector2Array([-40, 0, 0, -20, 40, 0, 0, 20])
	pad.color = color.darkened(0.35)
	add_child(pad)
	_pad = pad

	var name_label := Label.new()
	name_label.name = "Name"
	name_label.position = Vector2(-60, -66)
	name_label.custom_minimum_size = Vector2(120, 0)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	name_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	name_label.add_theme_constant_override("outline_size", 3)
	name_label.text = info.get("name", station_id)
	add_child(name_label)
	_name_label = name_label

	var cost_label := Label.new()
	cost_label.name = "Cost"
	cost_label.position = Vector2(-70, -46)
	cost_label.custom_minimum_size = Vector2(140, 0)
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_label.add_theme_font_size_override("font_size", 11)
	cost_label.add_theme_color_override("font_color", Color(1, 0.9, 0.5, 0.95))
	cost_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	cost_label.add_theme_constant_override("outline_size", 3)
	cost_label.text = _cost_text()
	add_child(cost_label)
	_cost_label = cost_label

func _cost_text() -> String:
	var cost: Dictionary = Recipes.BUILD_COSTS.get(station_id, {})
	var parts := PackedStringArray()
	for id: String in cost.get("inputs", {}):
		parts.append("%s x%d" % [GameItems.short_name(id), int(cost["inputs"][id])])
	return "Construir: " + ", ".join(parts) if not parts.is_empty() else ""

func build() -> void:
	built = true
	var info := Recipes.station_info(station_id)
	_pad.color = Color(info.get("color", "#888888"))
	_cost_label.text = "Lista (E)"
	_cost_label.add_theme_color_override("font_color", Color(0.7, 1, 0.7, 1))

func build_cost() -> Dictionary:
	return Recipes.BUILD_COSTS.get(station_id, {})

func debug_state() -> String:
	return "id=%s built=%s" % [station_id, built]
