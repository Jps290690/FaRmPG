extends Node

# Ajustes del jugador persistidos en user://settings.json (Fase 8).
# Accesible globalmente como autoload "Settings".

const SETTINGS_PATH := "user://settings.json"

var click_move := true
var wasd_move := true
var music_enabled := true
var music_volume := 0.6
var sfx_enabled := true
var sfx_volume := 0.8

func _ready() -> void:
	load_settings()

func load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	var f := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if f == null:
		return
	var data: Variant = JSON.parse_string(f.get_as_text())
	if not (data is Dictionary):
		return
	click_move = bool(data.get("click_move", click_move))
	wasd_move = bool(data.get("wasd_move", wasd_move))
	music_enabled = bool(data.get("music_enabled", music_enabled))
	music_volume = float(data.get("music_volume", music_volume))
	sfx_enabled = bool(data.get("sfx_enabled", sfx_enabled))
	sfx_volume = float(data.get("sfx_volume", sfx_volume))

func save_settings() -> void:
	var data := {
		"click_move": click_move,
		"wasd_move": wasd_move,
		"music_enabled": music_enabled,
		"music_volume": music_volume,
		"sfx_enabled": sfx_enabled,
		"sfx_volume": sfx_volume,
	}
	var f := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(data, "  "))