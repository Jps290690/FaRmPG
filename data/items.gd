class_name GameItems
extends RefCounted

enum ItemType { RESOURCE, TOOL, WEAPON, ARMOR }

const ITEMS := {
	# Recursos crudos
	"wood": {"name": "Madera", "short": "Madera", "type": ItemType.RESOURCE, "weight": 0.5},
	"stone": {"name": "Piedra", "short": "Piedra", "type": ItemType.RESOURCE, "weight": 1.0},
	"fiber": {"name": "Fibra", "short": "Fibra", "type": ItemType.RESOURCE, "weight": 0.3},
	"leather": {"name": "Cuero", "short": "Cuero", "type": ItemType.RESOURCE, "weight": 0.8},
	"mineral": {"name": "Mineral", "short": "Mineral", "type": ItemType.RESOURCE, "weight": 1.5},
	# Materiales refinados (Fase 5)
	"planks": {"name": "Tablas", "short": "Tablas", "type": ItemType.RESOURCE, "weight": 0.6},
	"metal_bar": {"name": "Lingote de metal", "short": "Lingote", "type": ItemType.RESOURCE, "weight": 2.0},
	"cloth": {"name": "Tela", "short": "Tela", "type": ItemType.RESOURCE, "weight": 0.4},
	"cured_leather": {"name": "Cuero curtido", "short": "C. curtido", "type": ItemType.RESOURCE, "weight": 1.0},
	# Herramientas base (con durabilidad)
	"axe": {"name": "Hacha", "short": "Hacha", "type": ItemType.TOOL, "weight": 3.0, "durability": 100, "harvest": "wood", "skill": "tala"},
	"pickaxe": {"name": "Pico", "short": "Pico", "type": ItemType.TOOL, "weight": 3.5, "durability": 100, "harvest": "stone", "skill": "mining"},
	"sickle": {"name": "Hoz", "short": "Hoz", "type": ItemType.TOOL, "weight": 2.0, "durability": 100, "harvest": "fiber", "skill": "gathering"},
	"skinning_knife": {"name": "Cuchillo de desollar", "short": "Cuchillo", "type": ItemType.TOOL, "weight": 1.5, "durability": 100, "harvest": "leather", "skill": "hunting"},
	# Herramientas T1 (Fase 5) — reemplazan a las base
	"metal_axe": {"name": "Hacha de metal", "short": "H. metal", "type": ItemType.TOOL, "weight": 3.0, "durability": 250, "harvest": "wood", "skill": "tala"},
	"metal_pickaxe": {"name": "Pico de metal", "short": "P. metal", "type": ItemType.TOOL, "weight": 3.5, "durability": 250, "harvest": "stone", "skill": "mining"},
	"metal_sickle": {"name": "Hoz de metal", "short": "Hoz metal", "type": ItemType.TOOL, "weight": 2.0, "durability": 250, "harvest": "fiber", "skill": "gathering"},
	"metal_knife": {"name": "Cuchillo de metal", "short": "C. metal", "type": ItemType.TOOL, "weight": 1.5, "durability": 250, "harvest": "leather", "skill": "hunting"},
	# Arma y armadura T1 (Fase 5)
	"sword": {"name": "Espada de hierro", "short": "Espada", "type": ItemType.WEAPON, "weight": 4.0},
	"chestplate": {"name": "Peto de cuero", "short": "Peto", "type": ItemType.ARMOR, "weight": 6.0},
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
