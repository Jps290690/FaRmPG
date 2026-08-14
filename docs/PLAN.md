# AutoGodot — Plan de diseño

> RPG pixel-art isométrico PVE · farmeo estilo Albion · single-player · corre en navegador.
> Este archivo es la fuente de verdad del diseño. Leerlo al inicio de cada sesión.

## Stack técnico

- **Motor:** Godot 4.6 (proyecto ya configurado) · GDScript
- **Plataforma:** Export HTML5 (WebGL) → **GitHub Pages**. Repo **privado**, sitio público. Build automático con GitHub Actions (`chickensoft-games/setup-godot` instala Godot + export templates, `deploy-pages` publica).
- **Guardado:** Autosave en `user://` → IndexedDB del navegador.
- **Arte:** Packs pixel-art isométrico **CC0** (Kenney / itch.io), tiles **32x32 escala 2x**. Audio CC0.
- **Control dual:** click-to-move y WASD, ambos activos, conmutable desde ajustes.

## Mundo (1 zona handcrafted)

Una zona isométrica con 4 biomas de recursos + base del jugador en el centro.

| Zona | Recurso | Aspect guardián |
|---|---|---|
| Bosque de Ents | Madera | Ent (patrulla) |
| Cantera | Piedra / Mineral | Golem (lento, letal) |
| Pradera | Piel/Cuero | Caza mayor rara |
| Arboleda de Dríades | Fibra | Dríade (sigilosa) |

## Ciclo de juego central

`Recolectar (herramienta + skill)` → `Refinar (estación de base)` → `Craftear (set T1)` → `Equiparse` → `Vender excedente a NPC` → repetir

## Los 4 Aspectos (mecánicas distintivas)

1. **Ent** — Patrulla su zona en ronda. Si farmeás un árbol mientras está cerca, se enfada (estilo señor de los anillos). **No se calma mientras sigas ahí**: solo se le pasa si salís de su zona de agresión (como Albion). Mientras patrulla lejos, podés talar sin riesgo.
2. **Golem** — Lento pero letal. Ataca en melee con **telegrafía clara** (el núcleo brilla antes del golpe) → podés esquivar. Alto daño.
3. **Caza mayor** — Animal raro que spawnea poco, da **muchísimo cuero**, y **huye al instante** si te detecta. Cacería con planificación.
4. **Dríade** — **Sigilosa y venenosa**: camuflada entre árboles de fibra, te sorprende si te acercás mucho; su veneno aplica DoT.

## Sistemas clave

- **4 skills por oficio** (Tala, Minería, Cosecha, Caza), cada una con 3 efectos: **+yield** por nodo, **+velocidad** de recolección, **desbloqueo de recetas** del oficio.
- **Equipamiento T1:** 4 herramientas (hacha, pico, hoz, cuchillo de desollar) + arma básica + armadura simple. Sistema de armas preparado para expandir.
- **Capacidad limitada + durabilidad:** inventario con peso/espacios, herramientas se desgastan (rehacer o reparar).
- **Crafteo por estaciones en la base:** Taller de madera, Forja, Telar, Curtiduría. Obliga a viajes base↔zona.
- **Muerte = perder inventario** que llevabas; respawn en la base.
- **Economía dinámica oferta/demanda:** el NPC ajusta precio de compra/venta por recurso según cuánto vendiste/compraste (recálculo por visita). Si vendés mucha piedra, baja; si nunca vendiste mineral, comprarlo sale caro pero venderlo paga bien.
  - **Futuro (post-POC):** eventos de mercado — caravana de leñadores baja la madera; incendio lejano sube la demanda de madera.

## Interfaz (POC)

Hotbar + Inventario + Panel de skills/recetas + Dialogo de vendedor + Pantalla de muerte + Ajustes (control click/WASD, audio).

## Meta del POC ("ganar")

Craftear el **set T1 completo** (herramientas de metal + armadura + arma) **y construir todas las estaciones** de la base.

## Estructura de carpetas

```
scenes/   (main, player, base, aspects, npc, ui)
scripts/  (sistemas: gathering, inventory, skills, economy, combat, save)
data/     (items, recetas, nodos, precios — .tres/JSON)
assets/   (textures/, audio/, tilesets/)
```

## Fases de implementación

1. **Cimientos:** export web + GitHub Actions + GitHub Pages funcionando con un build placeholder.
2. **Mapa y movimiento:** isométrico, 4 biomas, base central, cámara, controles click+WASD.
3. **Recolección + skills:** nodos, herramientas con durabilidad, 4 skills con sus 3 efectos.
4. **Inventario + hotbar + peso.**
5. **Refinado/crafteo por estaciones + set T1.**
6. **Aspectos + combate + muerte con pérdida.**
7. **NPC + economía dinámica.**
8. **Autosave + audio + pulido UI.**
9. **Balance y testeo del ciclo completo.**

## Decisiones de diseño tomadas (registro)

| Decisión | Elección |
|---|---|
| Vista/controles | Isométrico top-down; click-to-move **y** WASD |
| Combate | Aspectos con mecánicas distintivas; pocas armas al inicio, sistema extensible |
| Economía | Vendedores NPC + base propia; precios dinámicos oferta/demanda; eventos post-POC |
| Alcance POC | Ciclo completo mínimo (1 zona, 3-4 recursos, refinar, 5-10 recetas, inventario, autosave) |
| Assets | Packs CC0 gratuitos |
| Hosting | GitHub Pages (repo privado, sitio público) |
| Guardado | Autosave local (IndexedDB) |
| Progresión | Niveles de skill + tier de herramientas |
| Muerte | Perder inventario que llevabas; respawn en base |
| Inventario | Capacidad limitada + durabilidad |
| Mapa | 1 zona grande handcrafted con biomas |
| Crafteo | Por estaciones en la base |
| Audio | Música + SFX desde el POC |
| Resolución | 32x32 escala 2x |
| UI | Hotbar + inventario + skills |
| Equipamiento base | Herramientas + arma + armadura básica |
| Ent | Enfado por farmeo cercano, no se calma en la zona, patrulla |
| Golem | Lento, letal, ataque telegrafiado |
| Animal | Caza mayor rara, huye al instante |
| Dríade | Sigilosa y venenosa |
| Economía POC | Oferta/demanda simple sin eventos |
| Skills | 4 skills por oficio, 3 efectos c/u |
| Meta POC | Craftear set T1 completo + todas las estaciones |

---

## Notas de sesión (contexto para retomar el trabajo)

### Visión (opencode-vision MCP) — configurado
- MCP de visión activo en `~/.config/opencode/opencode.jsonc` (server `opencode_vision.server`, parches aplicados en `C:\Users\Juampi\opencode-vision\`, API key en `~/.config/opencode/.env`).
- Cuando el usuario dice **"usá la tool de visión"**: usar `vision_analyze` / `vision_describe` / `vision_clipboard` sobre las capturas del juego.
- Verificado: el MCP analiza imágenes correctamente (probado con `capturas/fase2_juego.png`).

### Estado del juego (Fase 2 — VERIFICADA ✓)
- El mundo isométrico está implementado y **verificado visualmente con la tool de visión**:
  - `capturas/fase2_mapa_completo.png` (zoom-out 0.42): 4 biomas correctamente ubicados (bosque verde oscuro arriba-izq, cantera gris arriba-der, pradera verde claro abajo-izq, arboleda verde azulado abajo-der) + base marrón central con borde de hierba + jugador (rombo naranja) centrado.
  - `capturas/fase2_ventana.png` (zoom 1.5): render de la base y biomas adyacentes, HUD de controles visible. Sin errores en log.
- Captura de ventana: `capture_screenshot` del MCP toma todo el escritorio (2 monitores) — para capturar solo la ventana del juego usar PrintWindow via PowerShell (ver técnica en `tutorial_vision.md`).
- El repo es público (Jps290690/FaRmPG) y el deploy de GitHub Pages ya funciona: https://Jps290690.github.io/FaRmPG/

### Estado del juego (Fase 3 — VERIFICADA ✓)
- **Recolección completa y verificada en runtime:** nodos de recurso (wood/stone/fiber/leather/mineral) con 5 usos y respawn (12s), 4 herramientas con durabilidad (axe/pickaxe/sickle/skinning_knife, 100), 4 skills con XP y niveles (curva 20·(lv+1)), peso de inventario (30 kg).
  - Ciclo probado: 5 golpes → `wood x5`, hacha 95/100, Tala L1 (xp 10/40), peso 12.5/30; nodo agotado (`harvestable=false`), respawn a los 12s.
  - HUD en vivo: `capturas/fase3_hud.png` muestra Tool (`Hacha 99/100`), Inventory (`Inventario (10/30 kg) Madera x1`) y Skills (`Tala L0 · Minería L0 · Cosecha L0 · Caza L0`). Cero errores en godot.log.
- **Lecciones técnicas (Godot 4.6) — importantes:**
  - **Input actions:** las acciones custom van en la sección `[input]` de `project.godot` (propiedades `input/<accion>`), NO `[input_map]` (ignorada por `InputMap::load_from_project_settings()`).
  - **Grupos en tscn:** `groups = ["player"]` sobre un nodo instanciado NO se aplica en runtime → usar `add_to_group()` en `_ready()`.
  - **Nombres de funciones estáticas:** NO nombrar una función estática `is_tool` en una clase `class_name` — colisiona con el campo de metadata `"is_tool"` del class cache (falla "Expected 0 argument(s)" con binding estático). Usar `is_tool_item`.
  - **Timing `_ready`:** el player `_ready` corre antes que el HUD `_ready` → el HUD debe refrescar en su propio `_ready` y guardar con `is_node_ready()`.
  - **Bridge input:** `runtime_input` inyecta `keycode` + `physical_keycode` (fix en `addons/godot-mcp/runtime_bridge.gd`), necesario para acciones con `physical_keycode`.
- Siguiente tarea: **Fase 4 — Inventario + hotbar + peso** (UI de inventario desplegable, hotbar, manejo de peso visual).

### Estado del juego (Fase 4 — VERIFICADA ✓)
- **Inventario + hotbar + peso implementados y verificados en runtime:**
  - **Hotbar** de 8 slots (teclas 1-8) con botones toggle. Orden: herramientas fijas [Hacha, Pico, Hoz, Cuchillo] y luego recursos. Texto del slot = nombre corto + durabilidad (tools) o cantidad (recursos); vacíos deshabilitados; tooltip = nombre completo; seleccionado resaltado con `button_pressed`.
  - **Herramienta equipada:** el jugador empieza con `equipped = "axe"`. Teclas 1-8 / click en slot equipan la herramienta (`select_slot`); el label inferior muestra "Equipado: <nombre> cur/max".
  - **Recolección con herramienta equipada:** `_try_gather` valida contra la tool equipada (no contra inventario): mensajes "Equipá una herramienta (hotbar 1-8).", "Necesitás <tool> equipado." o "Tu <tool> está rota.". Si la herramienta se rompe al recolectar, se desequipa (`equipped=""`) y avisa "Tu <tool> se rompió.".
  - **Panel de inventario (tecla B):** PanelContainer centrado con título, barra de peso (ProgressBar max 30 kg, color verde/naranja/rojo según ratio >0.7/>0.9), separador y lista de ítems (tools: "Hacha 99/100 (3.0 kg)", recursos: "Madera x1 (0.5 kg)"). Toggle con B (`toggle_inventory`), refresca al abrir.
  - **Label inferior** "Inventario (X/30 kg)" movido arriba (offset -96/-68) para no solaparse con la hotbar.
- Verificación runtime (PID 2188): `equipped=pickaxe` al presionar tecla 2; "Necesitás Hacha equipado." al recolectar madera con pico; con hacha → `axe dur 99`, `wood x1`, peso 10.5/30, XP tala 6; hotbar muestra "Hacha 99"; panel con filas correctas y barra en 10.5. Log sin errores. Capturas: `capturas/fase4_hotbar.png` y `capturas/fase4_panel.png`.
- **Lección técnica (Godot 4.6):** con `hud` tipado como `Node`, `var id := hud.hotbar_id_at(...)` falla ("Cannot infer the type") porque el retorno es Variant → tipar explícitamente (`var id: String = ...`) o castear el evento (`var kce: InputEventKey = event`).

### Estado del juego (Fase 5 — VERIFICADA ✓)
- **Refinado + crafteo por estaciones + set T1 implementados y verificados en runtime:**
  - **4 estaciones** en la base (Taller de madera, Forja, Telar, Curtiduría) en rombos de color con nombre y costo. Se construyen con E si tenés skill L4 del oficio + materiales (ejs.: Taller = Madera x10, Forja = Piedra x10 + Mineral x5). Al construirse cambian a "Lista (E)" (verde).
  - **Panel de crafteo** (E junto a estación construida): lista recetas de esa estación, refinado primero y luego T1; botón Craftear deshabilitado con tooltip ("Requiere <skill> L2" o "Faltan materiales"). E cierra el panel.
  - **Recetas:** 4 de refinado (Madera x3→Tablas, Mineral x2→Lingote, Fibra x4→Tela, Cuero x3→Cuero curtido) + 6 T1 (4 herramientas de metal dur 250 que **reemplazan** a la base con `replaces`, Espada de hierro, Peto de cuero). Requisito de skill por receta (L2 herramientas, L3 arma/armadura).
  - **Nuevo recurso Mineral** en la cantera (3 usos, 2.4s, nodo azulado) — insumo de la forja.
  - **Meta del POC implementada** (`_check_meta`): construir las 4 estaciones + tener el set T1 completo (4 herramientas metal + espada + peto) → mensaje "¡Objetivo del POC cumplido!".
- Verificación runtime (PID 1168): 4 estaciones visibles con costos; sin materiales → "Requiere Tala L4"; con Tala L4 + Madera x10 → `lumber_workbench built=true`; panel muestra "Tablas" y "Hacha de metal" con botones; `craft("refine_planks")` → wood 9→6, planks x1, peso 13.6; `craft("craft_axe")` → axe consumida, `metal_axe dur 250`, peso 13.0; construidas las 4 estaciones; set T1 completo (peso 27/30) → mensaje de meta. Log sin errores. Capturas: `capturas/fase5_estaciones.png`, `capturas/fase5_craftpanel.png`, `capturas/fase5_meta.png`.
- **Lección técnica (Godot 4.6):** los `class_name` nuevos (`Station`, `Recipes`, `GameItems`) se usan como tipos estáticos desde otros scripts; si el editor está abierto hay que dejarlo reimportar los scripts antes de correr (el play desde editor los compila igual). El runtime bridge puede fallar con "Failed to listen on 127.0.0.1:9877 (err 22)" si quedó un proceso zombie de una sesión anterior ocupando el puerto → matar el proceso y relanzar.
- Siguiente tarea: **Fase 6 — Aspectos + combate + muerte con pérdida** (Ent, Golem, caza mayor, Dríade; combate con la espada; perder inventario al morir, respawn en base).

### Estado del juego (Fase 6 — VERIFICADA ✓)
- **Aspectos guardianes + combate + muerte con pérdida implementados y verificados en runtime** (nombres reales en runtime: `Ent1`, `Golem2`, `Boar3`, `Dryad4`, `Dryad5`):
  - **Ent** (bosque, 80hp, 15 dmg, rango 240): se enfada si talás cerca (2s, 240px) o al recibir daño (`_on_hurt`); ojos amarillos, persigue a 110px/s; se calma 3s después de que salgas de su zona.
  - **Golem** (cantera, 120hp, 40 dmg, rango 260, telegraph 0.8s con núcleo que se agranda y aclara): aggro **solo si el jugador está dentro de la cantera** (fix spawn-kill en base); pierde aggro si salís de la zona y te alejás >1.4x rango.
  - **Jabalí** (pradera, 40hp, no ataca): huye a 190px/s si te acercás a 260px o recibe daño; al morir suelta `leather x8` (único con loot por diseño).
  - **Dríade** (arboleda, 60hp, 10 dmg + veneno 3dps×5s): camuflada (alpha 0.2), se revela a 110px o al recibir daño; vuelve a camuflarse si te alejás de su zona (>1.8x rango).
  - **Combate jugador:** Space ataca al aspecto más cercano a ≤65px; espada 25 dmg (cd 0.6), puños 5. Al morir el aspecto: `queue_free`, barra de HP visible solo si tiene daño, flash rojo al recibir golpe.
  - **Muerte con pérdida:** al morir se pierde TODO el inventario y el equipamiento; panel de muerte + mensaje; R respawnea en la base (1536,576) con las 4 tools starter.
- **Bugs encontrados y arreglados en sesión (el jugador "revivía y volvía a morir"):**
  1. El respawn no limpiaba el veneno (el DoT seguía tickeando al revivir) → `_die()` y `_respawn()` resetean `_poison_dps/_poison_left/_poison_timer` y `sprite.modulate`.
  2. **Causa raíz real:** los aspectos hostiles (Dríade/Golem) perseguían al jugador hasta la base y lo mataban al instante al respawnear (spawn-kill en loop) — la dríade nunca se calmaba y el golem aggroaba por proximidad desde la base. Fixes: `calm()` en `Aspect` (resetea hostile + estado visual, llamado en `_die()` y `_respawn()`), los aspectos no actúan mientras el jugador está muerto (`_physics_process` early-return), aggro del golem requiere estar en su zona, y la dríade se deshostiliza al alejarse.
  3. El Ent/Golem no reaccionaban al ser atacados → hook `_on_hurt()` en `Aspect.take_damage` (por defecto `hostile=true`; Ent enciende ojos + calm 3s; Dryad se revela; Boar ya huía por `take_damage` override).
- Verificación runtime: Ent enfadado por tala (tiempo desde gather 3.33s → hostile), muerte por Ent (hp 0, inventario vacío), aggro y telegraph del Golem, fuga del Jabalí (1042px en 1s) + `leather x8` al morir, revelación y veneno de la Dríade (poison 5s, DoT letal), espada: 60→35→10 hp a la Dríade y remate al Ent (80→20→muerto, `node not found`), respawn limpio: 15s en la base sin re-muerte con golem/dríade calmados y en sus zonas. Capturas: `capturas/fase6_base.png`, `capturas/fase6_muerte_ent.png`, `capturas/fase6_dryad_veneno.png`.
- **Lecciones técnicas (Godot 4.6):** el runtime bridge (`runtime_call_method`) pasa args JSON crudos a `callv()` — no convierte `{x,y}` a `Vector2`, pero `runtime_set_node` SÍ parsea `"Vector2(x,y)"` en properties; los métodos debug aceptan String `"x,y"`. Al editar scripts con el juego corriendo, reiniciar (`stop_project` + `run_project`) para cargar los cambios; los aspectos patrullan en tiempo real (re-leer posición antes de teleportar). El group de aspectos es `"aspects"` (Aspect se agrega solo en `_ready`).

### Estado del juego (Fase 7 — VERIFICADA ✓)
- **NPC comerciante + economía dinámica oferta/demanda implementados y verificados en runtime:**
  - **Moneda:** nuevo ítem `gold` (peso 0, no equipable). El jugador empieza con **100 de oro** (`STARTING_GOLD`); respawn devuelve las tools + oro. Aparece en hotbar/inventario como recurso normal.
  - **NPC Comerciante** (`scripts/npc/merchant.gd`, clase `Merchant`, grupo `merchants`): rombo dorado con label "Comerciante (E)" en la base (centro + (0,-176)). E lo abre (prioridad sobre estaciones, `MERCHANT_RANGE` 95); E cierra el panel.
  - **Economía** (`data/economy.gd`, clase `Economy`, var `player.economy`): `BASE_PRICES` por recurso (wood/stone 4, fiber 6, leather 10, mineral 20; refinados: planks 12, metal_bar 40, cloth 18, cured_leather 24). `_volume[id]` = neto vendido (ventas - compras). Precios por visita:
    - **Venta** al NPC = `base × 0.5 / (1 + 0.15 × volumen)` → vendés mucho, baja (madera 2g → 1g tras 3 ventas).
    - **Compra** del NPC = `base × 1.5 × (1 + 0.15 × max(-volumen,0))` → comprás mucho, sube (mineral 30g → 44g tras 3 compras).
    - "Si nunca vendiste mineral": comprarlo sale caro (1.5x) pero venderlo paga bien (0.5x); el volumen acumulado lo corrige.
  - **Panel de comerciante** (HUD `MerchantPanel`): título + oro actual, 9 filas (recursos crudos + refinados) con precios de compra/venta, stock del jugador y botones **Comprar x1 / Vender x1**. Botones deshabilitados con tooltip (falta oro, inventario lleno, no tenés recurso). Vender/Comprar suman/restan oro y ajustan el volumen.
- Verificación runtime (PID 21580): E junto al NPC abre el panel (`merchant_open=true`); vender madera x3 → oro 100→106, precio venta madera 2g→1g (v=3); comprar mineral x3 → oro 106→2 (30+35+39g), precio compra mineral 30g→39g→44g (v=-3); sin oro → falla compra con mensaje; sin recurso → falla venta; E cierra el panel. Sin errores en log. Captura: `capturas/fase7_comercio.png`.
- **Lección técnica (Godot 4.6):** los `class_name` nuevos (`Economy`, `Merchant`) NO existen como tipos globales hasta que el editor escanea el proyecto → al agregar scripts con `class_name`, abrir el editor una vez para que regenere `global_script_class_cache.cfg` antes de correr (si no: "Parse Error: Identifier not declared"). `max()` devuelve Variant → no usar `:=` al inferir (warning tratado como error); tipar explícito (`var v: int = max(...)`).
- Siguiente tarea: **Fase 8 — Autosave + audio + pulido UI** (guardado en `user://`/IndexedDB, música + SFX, ajustes de control y audio).

### Estado del juego (Fase 8 — VERIFICADA ✓)
- **Autosave + audio procedural + pulido UI implementados y verificados en runtime:**
  - **Autosave** (`scripts/player.gd`): guarda en `user://save.json` (→ `%APPDATA%\Godot\app_userdata\Cosecha del Bosque\save.json` en Windows) con `version, inventory, skills, equipped, position, economy, stations`. Debounce de 1s al cambiar inventario/skills; guarda también al morir, al respawnear, al cerrar la ventana (`NOTIFICATION_WM_CLOSE_REQUEST`/`APPLICATION_PAUSED`) y con el botón "Guardar ahora". Se carga en `world._ready()` → `player.load_game()` (después de spawnear estaciones).
  - **Ajustes persistentes** (`scripts/settings.gd`, autoload `Settings`): `click_move`, `wasd_move`, `music_enabled/volume`, `sfx_enabled/volume` en `user://settings.json`. Panel `SettingsPanel` centrado (Esc abre/cierra, bloquea el input del juego mientras está abierto) con checkboxes de control click/WASD, sliders de música/efectos (0-100) y botón "Guardar ahora".
  - **Audio procedural** (`scripts/audio_manager.gd`, autoload `Audio`): WAV sintetizados a 22050 Hz 16-bit para SFX (gather, craft, buy, sell, attack, hurt, death, build, levelup, error, respawn) con pool de 8 players, y música en loop (acorde de 8s Am–F–C–G). `apply_settings()` respeta los toggles/volúmenes.
  - **SFX integrados** en el gameplay: golpe recibido, muerte, respawn, ataque, comprar/vender/error en el comerciante, recolectar (+ aviso de "¡Subiste X a nivel Y!"), construir estación, craftear.
  - **Gating de controles:** `Settings.click_move` gatea click-to-move/click-to-attack; `Settings.wasd_move` gatea WASD. Verificado en runtime con teclado real: WASD on → W mueve; WASD off → W no mueve (persistido en settings.json).
- **Bug real encontrado y arreglado:** el **WASD nunca funcionó** — Godot 4 NO incluye W/A/S/D en los `ui_*` por defecto (solo flechas), y el input map del proyecto no los tenía. Se agregaron las teclas físicas W/A/S/D a `ui_up/ui_down/ui_left/ui_right` en la sección `[input]` de `project.godot` (flechas + WASD). Tras el fix, el movimiento WASD funciona.
- **Verificación runtime (PID 17232):** save/load completo — `debug_add("wood",5)` → save.json (878 B) con wood x5, posición [1536,576], skills/stations; reinicio → estado restaurado idéntico (posición, inventario, skills, stations, economy); muerte por Dríade (hp 12, poison 5) → autosave post-muerte; respawn restaura hp 100 + kit inicial y limpia el veneno; panel de ajustes: Esc abre/cierra (`settings_open=true/false`), toggles y sliders persisten en settings.json; `play_sfx("gather")` sin errores. Log sin errores.
- **Lección técnica (Godot 4.6):** al testear movimiento con input sintético, el "W no mueve" puede deberse a (a) personaje **muerto** (`dead` anula `velocity`), (b) ventana sin foco de Windows (el motor descarta teclas inyectadas), o (c) `ui_*` sin W/A/S/D mapeados (ver fix arriba). Para verificar movimiento con teclado, preguntar al usuario que sostenga la tecla real. La herramienta MCP `add_input_binding` escribe en `[input_map]` que el loader IGNORA (lección ya registrada en Fase 3) → editar `project.godot` manualmente en `[input]`.
- Siguiente tarea: **Fase 9 — Balance y testeo del ciclo completo**.