class_name Recipes
extends RefCounted

# Estaciones de crafteo que se construyen en la base (Fase 5).
const STATIONS := {
	"lumber_workbench": {"name": "Taller de madera", "color": "#b8895a"},
	"forge": {"name": "Forja", "color": "#8d929a"},
	"loom": {"name": "Telar", "color": "#5fbf8b"},
	"tannery": {"name": "Curtiduría", "color": "#b07d4f"},
}

# Costo para construir cada estación y skill requerido (alineado con Skills.RECIPE_UNLOCKS).
const BUILD_COSTS := {
	"lumber_workbench": {"skill": "tala", "level": 4, "inputs": {"wood": 10}},
	"forge": {"skill": "mining", "level": 4, "inputs": {"stone": 10, "mineral": 5}},
	"loom": {"skill": "gathering", "level": 4, "inputs": {"fiber": 12}},
	"tannery": {"skill": "hunting", "level": 4, "inputs": {"leather": 8}},
}

# Recetas: id -> {name, station, inputs, outputs, skill, level, replaces}
# "replaces": herramienta base que se consume al craftear (upgrade T1).
const RECIPES := {
	# Refinado
	"refine_planks": {"name": "Tablas", "station": "lumber_workbench", "inputs": {"wood": 3}, "outputs": {"planks": 1}},
	"refine_metal_bar": {"name": "Lingote de metal", "station": "forge", "inputs": {"mineral": 2}, "outputs": {"metal_bar": 1}},
	"refine_cloth": {"name": "Tela", "station": "loom", "inputs": {"fiber": 4}, "outputs": {"cloth": 1}},
	"refine_cured_leather": {"name": "Cuero curtido", "station": "tannery", "inputs": {"leather": 3}, "outputs": {"cured_leather": 1}},
	# Set T1 — herramientas de metal (reemplazan a las base)
	"craft_axe": {"name": "Hacha de metal", "station": "lumber_workbench", "skill": "tala", "level": 2, "inputs": {"planks": 3, "metal_bar": 2}, "outputs": {"metal_axe": 1}, "replaces": "axe"},
	"craft_pickaxe": {"name": "Pico de metal", "station": "forge", "skill": "mining", "level": 2, "inputs": {"planks": 3, "metal_bar": 2}, "outputs": {"metal_pickaxe": 1}, "replaces": "pickaxe"},
	"craft_sickle": {"name": "Hoz de metal", "station": "loom", "skill": "gathering", "level": 2, "inputs": {"planks": 2, "metal_bar": 1}, "outputs": {"metal_sickle": 1}, "replaces": "sickle"},
	"craft_skinning_knife": {"name": "Cuchillo de metal", "station": "tannery", "skill": "hunting", "level": 2, "inputs": {"planks": 2, "metal_bar": 1}, "outputs": {"metal_knife": 1}, "replaces": "skinning_knife"},
	# Set T1 — arma y armadura
	"craft_sword": {"name": "Espada de hierro", "station": "forge", "skill": "mining", "level": 3, "inputs": {"planks": 2, "metal_bar": 3}, "outputs": {"sword": 1}},
	"craft_chestplate": {"name": "Peto de cuero", "station": "tannery", "skill": "hunting", "level": 3, "inputs": {"cured_leather": 6, "cloth": 2}, "outputs": {"chestplate": 1}},
}

const T1_SET := ["metal_axe", "metal_pickaxe", "metal_sickle", "metal_knife", "sword", "chestplate"]

static func station_info(id: String) -> Dictionary:
	return STATIONS.get(id, {})

static func recipe_info(id: String) -> Dictionary:
	return RECIPES.get(id, {})

# Recetas visibles en una estación: primero refinado, luego crafteo T1.
static func recipes_for_station(station_id: String) -> Array[String]:
	var out: Array[String] = []
	for id: String in RECIPES:
		if RECIPES[id].get("station", "") == station_id:
			out.append(id)
	out.sort_custom(func(a, b): return _recipe_priority(a) < _recipe_priority(b))
	return out

static func _recipe_priority(id: String) -> int:
	return 0 if RECIPES[id].has("level") else 1

static func can_afford(inv: Inventory, inputs: Dictionary) -> bool:
	for id: String in inputs:
		if not inv.has_item(id, int(inputs[id])):
			return false
	return true

static func skill_locked(skills: Skills, recipe: Dictionary) -> bool:
	if not recipe.has("skill"):
		return false
	return skills.level(String(recipe.skill)) < int(recipe.get("level", 0))

static func inputs_text(inputs: Dictionary) -> String:
	var parts := PackedStringArray()
	for id: String in inputs:
		parts.append("%s x%d" % [GameItems.short_name(id), int(inputs[id])])
	return ", ".join(parts)

# Peso neto resultante de aplicar la receta (positivo = agrega peso al inventario).
static func net_weight_change(recipe: Dictionary) -> float:
	var out := 0.0
	for id: String in recipe.get("outputs", {}):
		out += GameItems.info(id).get("weight", 0.0) * int(recipe["outputs"][id])
	for id: String in recipe.get("inputs", {}):
		out -= GameItems.info(id).get("weight", 0.0) * int(recipe["inputs"][id])
	return out
