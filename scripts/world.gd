extends Node2D

const TILE_W := 64
const TILE_H := 32
const MAP_W := 48
const MAP_H := 36
const BASE_RADIUS := 5

# Colores provisionales por bioma (rombos generados por código).
# Se reemplazarán por tilesets CC0 reales más adelante.
const COLORS := {
	"grass": Color("#5d8c3f"),
	"base": Color("#b8895a"),
	"forest": Color("#2f6b32"),
	"quarry": Color("#9aa0a8"),
	"prairie": Color("#8fbf55"),
	"grove": Color("#3f8f6b"),
}

var tile_sources := {
	"grass": 0,
	"base": 1,
	"forest": 2,
	"quarry": 3,
	"prairie": 4,
	"grove": 5,
}

@onready var ground: TileMapLayer = $Ground
@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Player/Camera2D
@onready var nodes_container: Node2D = $ResourceNodes
@onready var stations_container: Node2D = $Stations
@onready var aspects_container: Node2D = $Aspects
@onready var npcs_container: Node2D = $NPCs

# Distribución de nodos por bioma: tipo, tool, skill, cantidad.
const NODE_SPAWNS := {
	"forest": [["wood", "axe", "tala", 14], ["fiber", "sickle", "gathering", 2]],
	"quarry": [["stone", "pickaxe", "mining", 8], ["mineral", "pickaxe", "mining", 6]],
	"prairie": [["leather", "skinning_knife", "hunting", 8]],
	"grove": [["fiber", "sickle", "gathering", 12]],
}

# Posición de cada estación (alrededor del centro = base).
const STATION_SPOTS := {
	"lumber_workbench": Vector2(-192, -64),
	"forge": Vector2(192, -64),
	"loom": Vector2(-192, 64),
	"tannery": Vector2(192, 64),
}

func _ready() -> void:
	_build_tileset()
	_build_ground()
	_build_base_border()
	_spawn_resource_nodes()
	_spawn_stations()
	_spawn_aspects()
	_spawn_npcs()
	_center_camera_on_base()

func _biome_at(tx: int, ty: int) -> String:
	var dx := absf(tx - MAP_W / 2.0)
	var dy := absf(ty - MAP_H / 2.0)
	if dx <= BASE_RADIUS and dy <= BASE_RADIUS:
		return "base"
	if tx < MAP_W / 2.0 and ty < MAP_H / 2.0:
		return "forest"
	if tx >= MAP_W / 2.0 and ty < MAP_H / 2.0:
		return "quarry"
	if tx < MAP_W / 2.0 and ty >= MAP_H / 2.0:
		return "prairie"
	return "grove"

func _build_tileset() -> void:
	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(TILE_W, TILE_H)

	# Patrón de rombo isométrico para cada bioma.
	for key: String in COLORS:
		var img := Image.create(TILE_W, TILE_H, false, Image.FORMAT_RGBA8)
		var c: Color = COLORS[key]
		_draw_diamond(img, c)
		var tex := ImageTexture.create_from_image(img)
		var source := TileSetAtlasSource.new()
		source.texture = tex
		source.texture_region_size = Vector2i(TILE_W, TILE_H)
		source.create_tile(Vector2i(0, 0))
		tileset.add_source(source, tile_sources[key])

	ground.tile_set = tileset

func _draw_diamond(img: Image, c: Color) -> void:
	# Rombo 2:1 (64x32) con leve borde para dar relieve.
	var darker := c.darkened(0.35)
	for y in range(TILE_H):
		var half := TILE_H / 2.0
		var x_span := 1.0 - absf(y - half) / half  # 0..1
		var start := int(round((TILE_W / 2.0) - x_span * (TILE_W / 2.0)))
		var end := int(round((TILE_W / 2.0) + x_span * (TILE_W / 2.0)))
		for x in range(start, end):
			if y == 0 or x == start or x == end - 1:
				img.set_pixel(x, y, darker)
			else:
				img.set_pixel(x, y, c)

func _build_ground() -> void:
	for tx in range(MAP_W):
		for ty in range(MAP_H):
			var biome := _biome_at(tx, ty)
			ground.set_cell(Vector2i(tx, ty), tile_sources[biome], Vector2i(0, 0))

func _build_base_border() -> void:
	# Zona base rodeada de hierba para delimitar visualmente el centro.
	for tx in range(MAP_W):
		for ty in range(MAP_H):
			if _biome_at(tx, ty) != "base":
				continue
			var neighbor_border := false
			for dx in [-1, 0, 1]:
				for dy in [-1, 0, 1]:
					if _biome_at(tx + dx, ty + dy) != "base":
						neighbor_border = true
						break
				if neighbor_border:
					break
			if neighbor_border:
				ground.set_cell(Vector2i(tx, ty), tile_sources["grass"], Vector2i(0, 0))

func _spawn_resource_nodes() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1337
	var grid := {}
	for biome: String in NODE_SPAWNS:
		for spawn in NODE_SPAWNS[biome]:
			var resource: String = spawn[0]
			var tool: String = spawn[1]
			var skill: String = spawn[2]
			var count: int = spawn[3]
			var placed := 0
			var attempts := 0
			while placed < count and attempts < 400:
				attempts += 1
				var cell := _random_cell_in_biome(biome, rng)
				if cell in grid:
					continue
				if _too_close_to_base(cell):
					continue
				grid[cell] = true
				var node := ResourceNode.new()
				node.resource_type = resource
				node.tool_required = tool
				node.skill = skill
				node.max_amount = _amount_for(resource)
				node.gather_time = _gather_time_for(resource)
				node.position = _cell_to_world(cell)
				nodes_container.add_child(node)
				placed += 1

func _random_cell_in_biome(biome: String, rng: RandomNumberGenerator) -> Vector2i:
	var half_w: int = MAP_W / 2
	var half_h: int = MAP_H / 2
	var margin := 4
	match biome:
		"forest":
			return Vector2i(rng.randi_range(margin, half_w - 4), rng.randi_range(margin, half_h - 4))
		"quarry":
			return Vector2i(rng.randi_range(half_w + 4, MAP_W - 1 - margin), rng.randi_range(margin, half_h - 4))
		"prairie":
			return Vector2i(rng.randi_range(margin, half_w - 4), rng.randi_range(half_h + 4, MAP_H - 1 - margin))
		"grove":
			return Vector2i(rng.randi_range(half_w + 4, MAP_W - 1 - margin), rng.randi_range(half_h + 4, MAP_H - 1 - margin))
	return Vector2i.ZERO

func _too_close_to_base(cell: Vector2i) -> bool:
	var dx := absi(cell.x - MAP_W / 2)
	var dy := absi(cell.y - MAP_H / 2)
	return dx <= BASE_RADIUS + 2 and dy <= BASE_RADIUS + 2

func _cell_to_world(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * TILE_W + TILE_W / 2.0, cell.y * TILE_H + TILE_H / 2.0)

func _amount_for(resource: String) -> int:
	match resource:
		"wood":
			return 5
		"stone":
			return 4
		"fiber":
			return 5
		"leather":
			return 2
		"mineral":
			return 3
	return 3

func _gather_time_for(resource: String) -> float:
	match resource:
		"wood":
			return 2.0
		"stone":
			return 2.4
		"fiber":
			return 1.4
		"leather":
			return 1.6
		"mineral":
			return 2.4
	return 1.8

func _center_camera_on_base() -> void:
	var center := Vector2(MAP_W / 2.0 * TILE_W, MAP_H / 2.0 * TILE_H)
	player.global_position = center

	# Límites de cámara = mundo completo.
	var world_px := Vector2(MAP_W * TILE_W, MAP_H * TILE_H)
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(world_px.x)
	camera.limit_bottom = int(world_px.y)

func _spawn_stations() -> void:
	var center := Vector2(MAP_W / 2.0 * TILE_W, MAP_H / 2.0 * TILE_H)
	for id: String in STATION_SPOTS:
		var station := Station.new()
		station.station_id = id
		station.position = center + STATION_SPOTS[id]
		stations_container.add_child(station)

func _spawn_npcs() -> void:
	var merchant := Merchant.new()
	merchant.name = "Merchant"
	var center := Vector2(MAP_W / 2.0 * TILE_W, MAP_H / 2.0 * TILE_H)
	merchant.position = center + Vector2(0, -176)
	npcs_container.add_child(merchant)

# Aspectos guardianes (Fase 6): [tipo, celda del mapa].
func _spawn_aspects() -> void:
	var plans := [
		["Ent", Vector2i(16, 8)],
		["Golem", Vector2i(32, 8)],
		["Boar", Vector2i(16, 26)],
		["Dryad", Vector2i(30, 26)],
		["Dryad", Vector2i(36, 30)],
	]
	for plan in plans:
		var aspect: Aspect
		match plan[0]:
			"Ent":
				aspect = EntAspect.new()
			"Golem":
				aspect = GolemAspect.new()
			"Boar":
				aspect = BoarAspect.new()
			"Dryad":
				aspect = DryadAspect.new()
		aspect.name = "%s%d" % [plan[0], aspects_container.get_child_count() + 1]
		aspect.position = _cell_to_world(plan[1])
		aspects_container.add_child(aspect)