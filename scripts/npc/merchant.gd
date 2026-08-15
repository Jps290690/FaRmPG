class_name Merchant
extends Node2D

func _ready() -> void:
	add_to_group("merchants")
	_build_visuals()

func _build_visuals() -> void:
	var sprite := PixelArt.make_sprite(self, PixelArt.SPRITES["MERCHANT"], PixelArt.PAL, 2)
	sprite.name = "Art"
	PixelArt.make_shadow(self, 40, 12)

	var label := Label.new()
	label.name = "Name"
	label.position = Vector2(-70, -56)
	label.custom_minimum_size = Vector2(140, 0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	label.add_theme_constant_override("outline_size", 3)
	label.text = "Comerciante (E)"
	add_child(label)

func debug_state() -> String:
	return "pos=%s" % [global_position]