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