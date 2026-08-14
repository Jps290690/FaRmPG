class_name Skills
extends RefCounted

signal changed

const MAX_LEVEL := 10
const XP_PER_GATHER := 6

const SKILLS := {
	"tala": {"name": "Tala"},
	"mining": {"name": "Minería"},
	"gathering": {"name": "Cosecha"},
	"hunting": {"name": "Caza"},
}

# Recetas que desbloquea cada skill por nivel (se usan en Fase 5 - Crafteo).
const RECIPE_UNLOCKS := {
	"tala": {2: ["craft_axe"], 4: ["craft_wood_station"]},
	"mining": {2: ["craft_pickaxe"], 4: ["craft_forge"]},
	"gathering": {2: ["craft_sickle"], 4: ["craft_loom"]},
	"hunting": {2: ["craft_skinning_knife"], 4: ["craft_tannery"]},
}

var _levels := {}
var _xp := {}

func _init() -> void:
	for s: String in SKILLS:
		_levels[s] = 0
		_xp[s] = 0

func level(skill: String) -> int:
	return int(_levels.get(skill, 0))

func xp(skill: String) -> int:
	return int(_xp.get(skill, 0))

func xp_for_next(skill: String) -> int:
	return 20 * (level(skill) + 1)

func add_xp(skill: String, amount: int) -> int:
	if skill not in SKILLS:
		return level(skill)
	var new_xp: int = int(_xp[skill]) + amount
	var lv: int = int(_levels[skill])
	while lv < MAX_LEVEL and new_xp >= 20 * (lv + 1):
		new_xp -= 20 * (lv + 1)
		lv += 1
	_levels[skill] = lv
	_xp[skill] = new_xp
	changed.emit()
	return lv

# Efecto 1 — Yield: +1 por recolección en niveles 3, 6 y 9.
func yield_bonus(skill: String) -> int:
	var lv := level(skill)
	var bonus := 0
	if lv >= 3:
		bonus += 1
	if lv >= 6:
		bonus += 1
	if lv >= 9:
		bonus += 1
	return bonus

# Efecto 2 — Velocidad: -8% de tiempo de recolección por nivel.
func speed_multiplier(skill: String) -> float:
	var lv := level(skill)
	return maxf(0.2, 1.0 - 0.08 * lv)

# Efecto 3 — Recetas desbloqueadas por nivel del oficio.
func unlocked_recipes(skill: String) -> Array:
	var out: Array = []
	for req_lv: int in RECIPE_UNLOCKS.get(skill, {}):
		if level(skill) >= req_lv:
			out.append_array(RECIPE_UNLOCKS[skill][req_lv])
	return out

func summary() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for s: String in SKILLS:
		out.append({"id": s, "name": SKILLS[s].name, "level": level(s), "xp": xp(s), "xp_next": xp_for_next(s)})
	return out

func debug_string() -> String:
	var parts := PackedStringArray()
	for s: String in SKILLS:
		parts.append("%s lv%d xp%d/%d" % [s, level(s), xp(s), xp_for_next(s)])
	return "; ".join(parts)

# Restaura niveles/XP guardados (Fase 8 - Autosave).
func restore(data: Dictionary) -> void:
	for s: String in SKILLS:
		var entry: Variant = data.get(s, {})
		if entry is Dictionary:
			_levels[s] = int(entry.get("level", 0))
			_xp[s] = int(entry.get("xp", 0))
	changed.emit()
