class_name PixelArt
extends RefCounted

# Arte procedural pixel-art (Fase 10 pulido): sprites definidos como filas de
# texto + paleta, generados a ImageTexture al vuelo. Sin assets externos.

const PAL := {
	".": Color(0, 0, 0, 0),
	"1": Color("#14100c"),
	"2": Color("#4a3220"),
	"3": Color("#6d4a2b"),
	"4": Color("#9a7448"),
	"5": Color("#27452a"),
	"6": Color("#3c6b3e"),
	"7": Color("#5d9c58"),
	"8": Color("#8fce7d"),
	"9": Color("#3a3f46"),
	"a": Color("#5c626a"),
	"b": Color("#8f97a3"),
	"c": Color("#b07d4f"),
	"d": Color("#f2c94c"),
	"e": Color("#c94f4f"),
	"f": Color("#e08fa8"),
	"g": Color("#6fb3e0"),
	"h": Color("#f2f2ea"),
	"i": Color("#e0802f"),
	"w": Color("#d8d8cf"),
	"F": Color("#e8b98a"),
	"T": Color("#5a3a22"),
	"K": Color("#9a7448"),
}

const PLAYER_PAL := {
	"H": Color("#2f5233"),
	"F": Color("#e8b98a"),
	"W": Color("#2c1f14"),
	"B": Color("#7a5a3c"),
	"S": Color("#3e2a18"),
	"D": Color("#241a12"),
}

# Jugador: 2 frames de caminar (14x14).
const PLAYER_A := [
	"......HH......",
	".....HHHH.....",
	".....HFFH.....",
	".....HWWH.....",
	"....HHHHHH....",
	"....HBBBBH....",
	"...HBBBBBBH...",
	"...HBBSSBBH...",
	"...HBBBBBBH...",
	"....BBBBBB....",
	"....BB..BB....",
	"....BB..BB....",
	"...DD....DD...",
	"..DDD....DDD..",
]
const PLAYER_B := [
	"......HH......",
	".....HHHH.....",
	".....HFFH.....",
	".....HWWH.....",
	"....HHHHHH....",
	"....HBBBBH....",
	"...HBBBBBBH...",
	"...HBBSSBBH...",
	"...HBBBBBBH...",
	"....BBBBBB....",
	"....BBBBBB....",
	".....BBBB.....",
	"...DD....DD...",
	"..DDD....DDD..",
]

# Árbol de bosque: variante redonda (18x24) y cónica (18x22).
const TREE_1 := [
	".......6666.......",
	"......666666......",
	".....66666666.....",
	".....66666666.....",
	"....6666666666....",
	"....6666666666....",
	"...666666666666...",
	"...666677666666...",
	"...667777766666...",
	"...666777776666...",
	"...666667766666...",
	"...666666666666...",
	"....6666666666....",
	"....6666666666....",
	".....66666666.....",
	"......666666......",
	"......666666......",
	".......TTTT.......",
	".......TTTT.......",
	".......TTTT.......",
	"......TTTTTT......",
	"......TTTTTT......",
	".....TTTTTTTT.....",
	"....TTTTTTTTTT....",
]
const TREE_2 := [
	".......6666.......",
	"......666666......",
	".....66666666.....",
	"....6677776666....",
	"....6667777666....",
	"...666667776666...",
	"...666666666666...",
	"...666666666666...",
	"...666666666666...",
	"...666666666666...",
	"...666666666666...",
	"...666666666666...",
	"....6666666666....",
	".....66666666.....",
	".....66666666.....",
	"......666666......",
	".......TTTT.......",
	".......TTTT.......",
	"......TTTTTT......",
	"......TTTTTT......",
	".....TTTTTTTT.....",
	"....TTTTTTTTTT....",
]
const STUMP := [
	"...TTTTTT...",
	"..TTTTTTTT..",
	"..T3TTTT3T..",
	"..TTTTTTTT..",
	"...TTTTTT...",
]

# Roca de piedra (16x8), agotada (14x5).
const ROCK := [
	".......99.......",
	".....99aa99.....",
	"....9aabbba9....",
	"...9aabbbbba9...",
	"...9aabbbbbba9..",
	"..99abbbbbbba99.",
	"..99aaaaaaaaaa99",
	".99999999999999.",
]
const ROCK_DEAD := [
	"....999999....",
	"..99aaaaaa99..",
	".99a9aa9a9a99.",
	".99aa9a9a9a99.",
	"99999999999999",
]

# Mineral con cristales azules (16x11), agotado (14x5).
const MINERAL := [
	".......99.......",
	".....99aa99.....",
	"....9aabbba9....",
	"...9gabbbbba9...",
	"...9gabbbbba9...",
	"..99gabbbbba99..",
	"..99gabbbbba99..",
	"..9gabbbbbba9...",
	".99gaaaaaaaaa99.",
	".99999999999999.",
	"....gg....gg....",
]
const MINERAL_DEAD := [
	"....999999....",
	"..99aaaaaa99..",
	".99a9aa9a9a99.",
	"99a9aa9a9a9999",
	"99999999999999",
]

# Arbusto de fibra con flores (14x8), agotado (10x5).
const BUSH := [
	"......66......",
	"....667766....",
	"...66777766...",
	"..66777f7766..",
	".66777f77f766.",
	"66777777777666",
	"66777777776666",
	".666666666666.",
]
const BUSH_DEAD := [
	"....44....",
	"..4.4..4..",
	"..4..44.4.",
	"...44.44..",
	"....22....",
]

# Ciervo mirando a la derecha (18x11).
const DEER := [
	"..........cc.......",
	"........ccccccc...",
	"..4cccccccccccc...",
	".4cccccccccccc....",
	".4cccccccccccc....",
	"4cccccccccccccc....",
	"4cccccccccccccc....",
	".4cccccccccccc.....",
	"..44cccccccc......",
	"..4...4...4...4..",
	".44..44..44..44..",
]

# Ent (20x23) con tronco y brazos; ojos aparte (10x3).
const ENT := [
	"......66666.......",
	".....6666666......",
	"....666666666.....",
	"...66666666666....",
	"...66766666666....",
	"...66777666666....",
	"..6666777666666...",
	"..6666666666666...",
	"..6666666666666...",
	"...66666666666....",
	"....666666666.....",
	"..TTTTTTTTTT......",
	".TTTTTTTTTTTT.....",
	".T3TTTTTTTT3T.....",
	".TTTTTTTTTTTT.....",
	".TTTTTTTTTTTT.....",
	"..TT3TTTT3TT......",
	"..TTTTTTTTTT......",
	"...TTTTTTTT.......",
	"...TT....TT.......",
	"...TT....TT.......",
	"..TTT....TTT......",
	"..TTT....TTT......",
]
const EYES := [
	"..dd...dd.",
	"..dd...dd.",
	"..dd...dd.",
]

# Golem de roca con núcleo (18x14).
const GOLEM := [
	"......9999......",
	".....99aabb99...",
	"....9abbbbbb9...",
	"...99bbbbbbb99..",
	"...9abbbbbbba9..",
	"..99abbbbbbba99.",
	"9aabjbbbbjaa9...",
	"9aabbbbbbbaa9...",
	"99aaabbbbaa99...",
	"..9aaaaaaaaa9...",
	"...999999999....",
	"...9.......9....",
	"..99.......99...",
	"..99.......99...",
]

# Jabalí mirando a la izquierda con colmillos (16x11).
const BOAR := [
	"....cccccc....",
	"...cccccccc...",
	"..cccccccccc..",
	".cccccccccccc.",
	"wcccccccdcccccc.",
	"wcccccccccccccc.",
	".ccccccccccccc..",
	"..ccccccccccc...",
	"...cccccccc....",
	"...c..c..c......",
	"..cc..cc..cc....",
]

# Dríade de hojas (12x15).
const DRYAD := [
	"......77....",
	".....7777...",
	".....7FF7...",
	"....777777..",
	"...77777777.",
	"..7777777777",
	".7787777777",
	".7777777777.",
	"..77777777..",
	"..77777777..",
	"...777777...",
	"...77..77...",
	"...77..77...",
	"..777..777..",
	"..777..777..",
]

# Estaciones (16x9-10).
const STATION_TABLE := [
	".......22.......",
	"......2332......",
	".....233332.....",
	"..22.233332.22..",
	".244.233332.244.",
	".244.233332.244.",
	"2442.233332.2442",
	"2442233333224422",
	".22222222222222.",
]
const STATION_FORGE := [
	"............22..",
	"....ii......222.",
	"...ihh.....2222.",
	"....ii....22222.",
	".......2222222..",
	".....22222222...",
	"..22.2222222....",
	".244.2222222....",
	"24422222222222.",
	".22222222222222.",
]
const STATION_LOOM := [
	"2..............2",
	"2.wwwwwwwwwwww.2",
	"2.wewwwwwwwwww.2",
	"2.wwwwwwwwwwww.2",
	"2..............2",
	"2..............2",
	"2222222222222222",
	"......2222......",
	"......2222......",
]
const STATION_TANNERY := [
	".22222222222222.",
	".2KKKKKKKKKKKK2.",
	".2KKKKKKKKKKKK2.",
	".2KKKKKKKKKKKK2.",
	".2KKKKKKKKKKKK2.",
	".22222222222222.",
	"..222......222..",
	"..2222....2222..",
]

# Mercader con toldo rayado (22x19).
const MERCHANT := [
	"..eeeeeeeeeeeeeeeeee..",
	"..ewwewwewwewwewweww..",
	"..wwewwewwewwewwewwew..",
	"..eeeeeeeeeeeeeeeeee..",
	".hhhhhhhhhhhhhhhhhhhh.",
	".hhhhhhhhhhhhhhhhhhhh.",
	"......cccccccc........",
	".....cccccccccc.......",
	".....ccdccccdcc.......",
	".....cccccccccc.......",
	".....cccccccccc.......",
	".....cccccccccc.......",
	".....cccccccccc.......",
	"......cccccccc........",
	"......cccccccc........",
	"......cc....cc........",
	"......cc....cc........",
	".....ccc....ccc.......",
	".....ccc....ccc.......",
]

# Decoraciones del terreno.
const DECOR_GRASS := [
	"..8..",
	"..8.8",
	".88.8",
	".8.88",
	".888.",
	"88888",
	"..2..",
]
const DECOR_FLOWER := [
	".f.f.",
	"fdfdf",
	"fdddf",
	".fdf.",
	"..2..",
]
const DECOR_ROCK := [
	"..99..",
	".9aa9.",
	"9aaaa9",
	"999999",
]
const DECOR_MUSHROOM := [
	"..e..",
	".eee.",
	"eehee",
	".eee.",
	"..22.",
	"..22.",
]
const DECOR_BUSH := [
	"..6666..",
	".666666.",
	"66777766",
	"66777766",
	"66666666",
	"..2222..",
]

const PUFF := ["h"]

const SPRITES := {
	"PLAYER_A": PLAYER_A,
	"PLAYER_B": PLAYER_B,
	"TREE_1": TREE_1,
	"TREE_2": TREE_2,
	"STUMP": STUMP,
	"ROCK": ROCK,
	"ROCK_DEAD": ROCK_DEAD,
	"MINERAL": MINERAL,
	"MINERAL_DEAD": MINERAL_DEAD,
	"BUSH": BUSH,
	"BUSH_DEAD": BUSH_DEAD,
	"DEER": DEER,
	"ENT": ENT,
	"EYES": EYES,
	"GOLEM": GOLEM,
	"BOAR": BOAR,
	"DRYAD": DRYAD,
	"STATION_TABLE": STATION_TABLE,
	"STATION_FORGE": STATION_FORGE,
	"STATION_LOOM": STATION_LOOM,
	"STATION_TANNERY": STATION_TANNERY,
	"MERCHANT": MERCHANT,
	"DECOR_GRASS": DECOR_GRASS,
	"DECOR_FLOWER": DECOR_FLOWER,
	"DECOR_ROCK": DECOR_ROCK,
	"DECOR_MUSHROOM": DECOR_MUSHROOM,
	"DECOR_BUSH": DECOR_BUSH,
}

# Convierte filas de texto + paleta en una ImageTexture (escala = px por char).
static func make_texture(rows: Array, pal: Dictionary, scale := 2) -> ImageTexture:
	var h := rows.size()
	var w := 0
	for r in rows:
		w = maxi(w, r.length())
	var img := Image.create(w * scale, h * scale, false, Image.FORMAT_RGBA8)
	for y in h:
		var row: String = rows[y]
		for x in row.length():
			var ch := row[x]
			if ch == "." or not pal.has(ch):
				continue
			var col: Color = pal[ch]
			for sy in scale:
				for sx in scale:
					img.set_pixel(x * scale + sx, y * scale + sy, col)
	return ImageTexture.create_from_image(img)

# Crea un Sprite2D con la base en y=0 y centrado horizontalmente (centered=false).
# ground: fila que toca el suelo (default: la última).
static func make_sprite(parent: Node2D, rows: Array, pal: Dictionary, scale := 2, ground := -1) -> Sprite2D:
	var tex := make_texture(rows, pal, scale)
	var s := Sprite2D.new()
	s.texture = tex
	s.centered = false
	var ground_row := rows.size() - 1 if ground < 0 else ground
	s.position = Vector2(-tex.get_width() / 2.0, -(ground_row + 1) * scale)
	parent.add_child(s)
	return s

# Sprite centrado (para adornos pequeños como ojos).
static func make_sprite_centered(parent: Node2D, rows: Array, pal: Dictionary, scale := 2) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = make_texture(rows, pal, scale)
	parent.add_child(s)
	return s

# Sombra elíptica suave debajo de un objeto (sprite con z_index -1).
static func make_shadow_texture(diam_x: int, diam_y: int, alpha := 0.35) -> ImageTexture:
	var img := Image.create(diam_x, diam_y, false, Image.FORMAT_RGBA8)
	var cx := diam_x / 2.0
	var cy := diam_y / 2.0
	for y in diam_y:
		for x in diam_x:
			var dx := (x + 0.5 - cx) / cx
			var dy := (y + 0.5 - cy) / cy
			var d := dx * dx + dy * dy
			if d <= 1.0:
				img.set_pixel(x, y, Color(0, 0, 0, alpha * (1.0 - d)))
	return ImageTexture.create_from_image(img)

static func make_shadow(parent: Node2D, diam_x: int, diam_y: int) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = make_shadow_texture(diam_x, diam_y, 0.35)
	s.position = Vector2(0, 2)
	s.z_index = -1
	parent.add_child(s)
	return s

# Hash determinista 0..1 a partir de coordenadas (variantes de tiles/sprites).
static func hash2(x: int, y: int) -> float:
	var n := x * 374761393 + y * 668265263
	n = (n ^ (n >> 13)) * 1274126177
	return float((n ^ (n >> 16)) & 0xFFFFFF) / float(0xFFFFFF)