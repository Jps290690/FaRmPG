class_name Inventory
extends RefCounted

signal changed

const MAX_WEIGHT := 30.0

# _slots[id] = {"count": int, "durability": float}
var _slots := {}

func add_item(id: String, qty: int = 1) -> bool:
	if qty <= 0:
		return true
	if total_weight() + GameItems.info(id).get("weight", 0.0) * qty > MAX_WEIGHT + 0.001:
		return false
	var slot: Dictionary = _slots.get(id, {"count": 0, "durability": GameItems.max_durability(id)})
	slot["count"] = int(slot.get("count", 0)) + qty
	_slots[id] = slot
	changed.emit()
	return true

func remove_item(id: String, qty: int = 1) -> bool:
	var slot: Dictionary = _slots.get(id, {})
	if int(slot.get("count", 0)) < qty:
		return false
	slot["count"] = int(slot.get("count", 0)) - qty
	if int(slot["count"]) <= 0:
		_slots.erase(id)
	else:
		_slots[id] = slot
	changed.emit()
	return true

func has_item(id: String, qty: int = 1) -> bool:
	return int(_slots.get(id, {}).get("count", 0)) >= qty

func count(id: String) -> int:
	return int(_slots.get(id, {}).get("count", 0))

func get_durability(id: String) -> float:
	return float(_slots.get(id, {}).get("durability", 0.0))

func total_weight() -> float:
	var w := 0.0
	for id: String in _slots:
		w += GameItems.info(id).get("weight", 0.0) * int(_slots[id].get("count", 0))
	return w

func can_add(id: String, qty: int = 1) -> bool:
	return total_weight() + GameItems.info(id).get("weight", 0.0) * qty <= MAX_WEIGHT + 0.001

# Consume una unidad de uso de la herramienta. Devuelve true si la herramienta
# sigue existiendo (con vida) tras el uso; false si se rompió (slot eliminado).
func use_tool(id: String) -> bool:
	if not has_item(id):
		return false
	var slot: Dictionary = _slots[id]
	slot["durability"] = float(slot.get("durability", GameItems.max_durability(id))) - 1.0
	if slot["durability"] <= 0.0:
		remove_item(id, 1)
	else:
		_slots[id] = slot
	changed.emit()
	return has_item(id)

func snapshot() -> Dictionary:
	return _slots.duplicate(true)

func debug_string() -> String:
	var parts := PackedStringArray()
	for id: String in _slots:
		parts.append("%s x%d (dur %.1f)" % [id, _slots[id].count, float(_slots[id].get("durability", 0.0))])
	parts.append("peso %.1f/%.1f" % [total_weight(), MAX_WEIGHT])
	return "; ".join(parts)
