class_name Economy
extends RefCounted

# Precios base (en oro) por recurso. Los refinados valen más que sus crudos.
const BASE_PRICES := {
	"wood": 4,
	"stone": 4,
	"fiber": 6,
	"leather": 10,
	"mineral": 20,
	"planks": 12,
	"metal_bar": 40,
	"cloth": 18,
	"cured_leather": 24,
}

const SELL_RATIO := 0.5
const BUY_MARKUP := 1.5
const PRESSURE := 0.15

# _volume[id] = neto vendido (ventas - compras).
# Vender mucho sube el volumen → baja el precio de venta (oferta).
# Comprar mucho baja el volumen → sube el precio de compra (demanda).
var _volume := {}

func volume(id: String) -> int:
	return int(_volume.get(id, 0))

func sell_price(id: String) -> int:
	var base: int = int(BASE_PRICES.get(id, 1))
	var v: int = max(volume(id), 0)
	return max(1, int(round(base * SELL_RATIO / (1.0 + PRESSURE * v))))

func buy_price(id: String) -> int:
	var base: int = int(BASE_PRICES.get(id, 1))
	var v: int = max(-volume(id), 0)
	return max(1, int(round(base * BUY_MARKUP * (1.0 + PRESSURE * v))))

func record_sell(id: String) -> void:
	_volume[id] = volume(id) + 1

func record_buy(id: String) -> void:
	_volume[id] = volume(id) - 1

func debug_string() -> String:
	var parts := PackedStringArray()
	for id: String in BASE_PRICES:
		parts.append("%s v=%d c=%dg v=%dg" % [id, volume(id), buy_price(id), sell_price(id)])
	return "; ".join(parts)