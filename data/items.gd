class_name GameItems
extends RefCounted

enum ItemType { RESOURCE, TOOL }

const ITEMS := {
	# Recursos
	"wood": {"name": "Madera", "short": "Madera", "type": ItemType.RESOURCE, "weight": 0.5},
	"stone": {"name": "Piedra", "short": "Piedra", "type": ItemType.RESOURCE, "weight": 1.0},
	"fiber": {"name": "Fibra", "short": "Fibra", "type": ItemType.RESOURCE, "weight": 0.3},
	"leather": {"name": "Cuero", "short": "Cuero", "type": ItemType.RESOURCE, "weight": 0.8},
	"mineral": {"name": "Mineral", "short": "Mineral", "type": ItemType.RESOURCE, "weight": 1.5},
	# Herramientas T1 (con durabilidad)
	"axe": {"name": "Hacha", "short": "Hacha", "type": ItemType.TOOL, "weight": 3.0, "durability": 100, "harvest": "wood", "skill": "tala"},
	"pickaxe": {"name": "Pico", "short": "Pico", "type": ItemType.TOOL, "weight": 3.5, "durability": 100, "harvest": "stone", "skill": "mining"},
	"sickle": {"name": "Hoz", "short": "Hoz", "type": ItemType.TOOL, "weight": 2.0, "durability": 100, "harvest": "fiber", "skill": "gathering"},
	"skinning_knife": {"name": "Cuchillo de desollar", "short": "Cuchillo", "type": ItemType.TOOL, "weight": 1.5, "durability": 100, "harvest": "leather", "skill": "hunting"},
}

static func info(id: String) -> Dictionary:
	return ITEMS.get(id, {})

static func name_of(id: String) -> String:
	return info(id).get("name", id)

static func short_name(id: String) -> String:
	return info(id).get("short", name_of(id))

static func is_tool_item(id: String) -> bool:
	return info(id).get("type", -1) == ItemType.TOOL

static func max_durability(id: String) -> float:
	return float(info(id).get("durability", 0))
