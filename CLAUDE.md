# Crank & Slash — contexto del proyecto

Juego para la consola **Playdate**, escrito en **Lua** con el SDK nativo. Es el proyecto de la Práctica Profesional 1 de Cristopher (Ingeniería Civil en Informática, UFRO). Género: arena survival / roguelite de acción, inspirado en Brotato y Vampire Survivors. Arte 1-bit monocromático.

Repositorio: github.com/Ertrax147/CrankAndSlash. Para compilar y probar: `pdc source CrankAndSlash.pdx` y abrir el `.pdx` en el Playdate Simulator. La manivela se simula en el panel de la parte inferior del simulador. No hay tests automáticos: cada paso se prueba jugando en el simulador.

---

## Cómo quiero trabajar contigo (leer primero)

Estoy aprendiendo desarrollo de videojuegos y Lua, y tengo que poder explicar todo el código en las revisiones con mi profesor. Por eso:

1. **Pasos pequeños.** Trabaja el paso que te pida del plan (sección "Plan de desarrollo"). Si dos pasos son tan chicos que no tienen nada que probar por separado, puedes juntarlos, pero avísame. No agregues funcionalidades que no pedí.
2. **Antes de escribir código**, explícame el plan en 3 a 5 líneas (qué archivos tocarás y qué harás) y espera mi confirmación. Para cambios muy chicos y claros (un ajuste de un valor, una corrección ya acordada) puedes avanzar y explicarme después.
3. **Toca lo mínimo.** No refactorices ni renombres cosas que no sean parte del paso. Si crees que algo debería reorganizarse, proponlo aparte y no lo hagas por tu cuenta. Si un cambio obliga a tocar algo fuera del paso (por ejemplo un bug que aparece por el cambio), avísame y explícame por qué antes de hacerlo.
4. **Explica en español simple** qué cambiaste y por qué. Evita jerga innecesaria.
5. **Dime cómo probarlo**: qué debo ver en el simulador si funciona bien. No puedes ejecutar el simulador, así que no afirmes que "funciona" sin decir que falta que yo lo pruebe.
6. **Comentarios en el código:** cada función nueva lleva una línea arriba explicando qué hace, más una nota dentro si hay algo que no es obvio (por qué se hace así). No comentes línea por línea.
7. **Git:** sigue el flujo de la sección "Flujo de trabajo con Git".
8. Si algo del diseño no está definido o tienes una duda, **pregúntame** en vez de decidir tú.

---

## Flujo de trabajo con Git

Ramas:
- `main`: versión estable, lista para mostrar al profesor. Solo recibe cambios desde `develop` cuando una etapa está probada.
- `develop`: rama de integración. Recibe las funcionalidades ya terminadas.
- `feature/rf-XX-nombre`: una rama por funcionalidad del plan, creada desde `develop`. Todo el desarrollo ocurre aquí.
- `docs/nombre`: cambios solo de documentación (como este archivo), desde `develop`.
- `experimento/nombre`: pruebas sin compromiso que no son parte del plan (por ejemplo probar un tileset). No se mergean a `develop` sin hablarlo.

Reglas para ti (Claude Code):
1. **Al empezar cada sesión**, revisa la rama actual (`git branch --show-current`) y el estado (`git status`). Dime en qué rama estamos y si hay cambios sin guardar.
2. **Nunca edites archivos estando en `main` o `develop`.** Si estamos en una de ellas, avísame y espera a que yo cambie a la rama de trabajo.
3. **Crea ramas y cambia de rama solo cuando yo te lo pida**, mostrándome el comando antes de ejecutarlo. Los commits locales sí los haces tú sin pedirme confirmación (ver regla 4). **Nunca hagas `push`, `merge`, `rebase` ni `push --force`** sin que yo lo pida de forma explícita en ese mensaje. Antes de cualquier comando que pueda descartar trabajo (`git restore`, `git clean`, `git reset`, borrar carpetas), revisa `git status` y avísame qué se perdería.
4. **Commits pequeños:** uno por paso del plan (o por grupo de pasos muy chicos), con formato `feat:`, `fix:` o `docs:` en español y sin tildes ni eñes. **Haz un commit local apenas termines cada paso, sin pedirme confirmación** (no sube nada y se puede corregir), para no acumular trabajo sin guardar y mantener los commits atómicos. Yo pruebo por tandas de varios pasos: al terminar una tanda, dime qué probar. Si algo falla, corrígelo con un commit `fix:`. El `push` y los PR siguen siendo solo cuando yo lo pida.
5. **Los Pull Requests los creo y mergeo yo** desde GitHub. Cuando una funcionalidad esté terminada, súbela con `push` (si te lo pido) y pásame el link de comparación (`https://github.com/Ertrax147/CrankAndSlash/compare/develop...rama`) junto con el título y la descripción del PR (criterios de aceptación y cómo probarla). No ejecutes `gh pr create` ni `gh pr merge`; `gh` está instalado y autenticado, pero solo úsalo para consultar estados.
6. Después de que yo mergee un PR, trae los cambios: `git checkout develop` y `git pull`, y recién ahí crea la rama de lo siguiente.

---

## Estado actual del juego (implementado y probado en el simulador, mergeado a `develop`)

### Qué hace el juego hoy
- **Mundo infinito con cámara:** el personaje (círculo relleno) se mueve con la cruceta y siempre se dibuja en el centro de la pantalla; el mundo se desplaza debajo de él. No hay bordes. El fondo es una grilla de puntos que permite notar el movimiento.
- **Arma cuerpo a cuerpo:** gira **sola** alrededor del personaje. Solo el círculo del extremo hace daño; la línea que lo une al personaje es solo visual.
- **Energía de la manivela:** girar la manivela (en cualquier sentido) carga una barra de energía. La energía baja sola con el tiempo. Cuanto más energía, más rápido gira el arma y más rápido dispara la pistola. Sin energía el arma sigue girando a velocidad base (nunca se detiene). La manivela **no apunta**: solo carga energía.
- **Pistola (arma a distancia):** se desbloquea al comenzar la **ronda 2**. Dispara sola al enemigo más cercano. Los proyectiles (círculos chicos) viajan en línea recta, hacen daño y desaparecen al golpear o al salir de la pantalla.
- **Rondas:** cada ronda dura 30 s. Se muestran la ronda y el tiempo restante arriba. Al terminar una ronda desaparecen los enemigos vivos y aparece el aviso "Ronda N" por 1,5 s. Las rondas siguen hasta que el jugador muere.
- **Enemigos** (dibujos animados de 2 cuadros): aparecen justo afuera del borde visible de la pantalla, cada 1 s, y persiguen al jugador. Hay 4 tipos y salen más variados a medida que avanzan las rondas: **fantasma** (normal, desde la ronda 1), **murciélago** (rápido y frágil, desde la 2), **araña** (rápida, en zigzag, desde la 3) y **oso** (tanque lento y resistente, hace 2 de daño, desde la 4).
- El arma les quita vida al tocarlos; después de un golpe, ese enemigo no puede recibir otro del arma por 0,4 s.
- Si un enemigo toca al jugador, este pierde 1 de vida y queda 1 s invulnerable (parpadea).
- Si la vida llega a 0 aparece "GAME OVER"; con el botón A se reinicia (vuelve a la ronda 1, sin pistola).
- Pantalla: vida (arriba a la izquierda), ronda (arriba al centro), tiempo (arriba a la derecha) y barra de energía (abajo a la izquierda).

### Provisorio (se reemplazará)
- La aparición de enemigos cada 1 s (`Config.SPAWN_INTERVAL`) es fija; debería depender de la ronda (dificultad creciente).
- El reinicio con A en `main.lua` es una versión mínima; falta una máquina de estados real.

### Valores actuales (ajustables, están al inicio de cada archivo)
| Módulo | Valores |
|---|---|
| Player | radio 8, velocidad 90 px/s, vida 5, invulnerabilidad 1 s |
| Weapon (ver `weapon_types.lua`) | Espada larga (inicial): órbita 30 px, 3 círculos de daño de radio 5, daño 1, 100°/s (base) a 450°/s (energía llena), espera por enemigo 0,5 s. Maza: 1 círculo de radio 6, 120 a 540°/s, 0,4 s. Mandoble: 4 círculos de radio 6, daño 2, 70 a 300°/s, 0,7 s (maza y mandoble definidos pero sin usar) |
| Ranged | cooldown de disparo 1,0 s (sin energía) a 0,2 s (energía llena), se desbloquea en la ronda 2 |
| Projectile | radio 3, velocidad 220 px/s, daño 1, pool de 20 |
| Energy | máximo 100, +0,12 por grado girado, −12 por segundo |
| Enemy (ver `enemy_types.lua`) | pool de 40. Fantasma: radio 7, 40 px/s, vida 3, daño 1. Murciélago: radio 6, 70 px/s, vida 2, desde ronda 2. Araña: radio 6, 55 px/s, vida 2, zigzag, desde ronda 3. Oso: radio 11, 22 px/s, vida 10, daño 2, desde ronda 4 |
| Round | duración 30 s, aviso de 1,5 s |
| Map | puntos cada 40 px (coordenadas de mundo), radio 1 |
| Combat | el daño por contacto y el tamaño de cada enemigo vienen de su tipo (`enemy_types.lua`) |
| Config | pantalla 400x240, dt = 1/30 (30 fps) |

---

## Arquitectura

Todo el código está en `source/`, organizado en carpetas por responsabilidad. Cada archivo tiene una sola responsabilidad y se carga con `import "carpeta/archivo"` desde `main.lua`. Los módulos son **tablas globales** (`Config`, `Pool`, `Collision`, `Energy`, `Round`, `Player`, `Camera`, `Map`, `WeaponTypes`, `Weapon`, `Enemy`, `Projectile`, `Ranged`, `Combat`, etc.). Las constantes van en mayúsculas al inicio del módulo, sin números sueltos en el código.

**Carpetas de `source/`:**
- `core/`: lo básico que usa todo el juego y no depende de nada del juego: `config`, `pool`, `collision`.
- `world/`: el mundo y la cámara: `camera`, `map`.
- `data/`: tablas con valores, sin lógica: `enemy_types`, `weapon_types`, `upgrades`. Para agregar un enemigo, arma o mejora se toca solo esta carpeta (más su dibujo en `images/`).
- `entities/`: lo que existe y se mueve en el juego: `player`, `enemy`, `weapon`, `projectile`, `gems`.
- `systems/`: las reglas del juego: `combat`, `difficulty`, `round`, `xp`, `stats`, `energy`, `ranged`.
- `images/`: los dibujos que usa el juego (lo que no se usa va en `arte/`, fuera de `source/`).
- `main.lua` (en la raíz de `source/`) conecta todo. **Pendiente:** sacar de `main.lua` el HUD, el menú de subida de nivel y el dibujo de hitbox a una carpeta `ui/`, y preparar la máquina de estados.

La tabla de abajo nombra los archivos sin carpeta.

| Archivo | Responsabilidad |
|---|---|
| `main.lua` | Carga todo, define `playdate.update()` (se llama ~30 veces por segundo), el HUD, el spawner provisorio, el aviso de ronda y el game over |
| `config.lua` | Constantes generales (tamaño de pantalla, dt, intervalo de aparición) |
| `pool.lua` | Object Pool genérico: `Pool.new(size, factory)`, `acquire()`, `release(obj)`, `releaseAll()`. Los objetos se crean una vez y se reutilizan con el campo `active` |
| `collision.lua` | `Collision.circles(...)` (círculo contra círculo, comparando distancias al cuadrado) y `Collision.aabb(...)` (rectángulos; aún sin usar) |
| `energy.lua` | Energía de la manivela: `update(dt)`, `ratio()` (0 a 1), `reset()` |
| `round.lua` | Temporizador y número de ronda. `update(dt)` devuelve `true` el frame en que empieza una ronda nueva |
| `player.lua` | Movimiento con cruceta, vida, invulnerabilidad, dibujo (siempre centrado vía cámara) |
| `camera.lua` | `Camera.x/y` sigue al jugador; `Camera.toScreen(worldX, worldY)` convierte posición de mundo a pantalla |
| `map.lua` | Fondo: grilla de puntos dibujada con `Camera.toScreen` |
| `weapon_types.lua` | Tabla de definiciones de armas (`ESPADA_LARGA`, `MAZA`, `MANDOBLE`): órbita, zona de daño como lista de círculos (`HITBOXES`), daño, velocidades, espera por enemigo y dibujo |
| `weapon.lua` | Lista de armas del jugador (`Weapon.list`): las coloca alrededor del jugador, las dibuja (con cadena o sin ella) y mueve su zona de daño (`w.hits`); su velocidad depende de `Energy.ratio()` |
| `enemy_types.lua` | Tabla con los tipos de enemigo (tamaño, velocidad, vida, daño, desde qué ronda, frecuencia, dibujo, zigzag), solo valores |
| `enemy.lua` | Enemigos con pool (`Enemy.pool`), cada uno con su tipo: `spawn()` (elige el tipo según la ronda, alrededor de la cámara), `closest(x, y)`, `update(dt)`, `draw()` (sprites animados) |
| `projectile.lua` | Proyectiles de la pistola con su propio pool: `spawn`, `update` (se liberan al salir de pantalla), `draw` |
| `ranged.lua` | La pistola: dispara sola al enemigo más cercano; cadencia según energía; empieza apagada y se enciende con `Ranged.unlocked` (la mejora "Pistola" del menú de nivel) |
| `gems.lua` | Gemas de XP que sueltan los enemigos (pool; si se llena recicla la más lejana); se recogen al tocarlas |
| `xp.lua` | Experiencia y nivel del jugador: `add`, `needed`, `ratio` |
| `stats.lua` | Modificadores de las estadísticas del jugador (vida extra, velocidad, daño, energía, cadencia, alcance de recogida y del arma); cada módulo los aplica a su valor base |
| `upgrades.lua` | Lista de mejoras que se ofrecen al subir de nivel (`available` decide si una se ofrece) y `pickChoices()` |
| `combat.lua` | Revisa colisiones arma-enemigo, proyectil-enemigo y enemigo-jugador y aplica el daño |

**Idea clave de la cámara:** toda la lógica (movimiento, colisiones, daño) trabaja en **coordenadas de mundo**; solo el dibujo convierte a pantalla con `Camera.toScreen`. Por eso `collision.lua` y `combat.lua` no dependen de la cámara. Cualquier cosa que necesite saber "si está dentro de la pantalla" (como borrar proyectiles) debe convertir con la cámara, no comparar contra `Config.SCREEN_W/H` directo.

**Orden de actualización por frame** (importa, no lo cambies sin avisar): `Energy.update` → `Round.update` (si empieza ronda nueva: `Enemy.reset` y aviso) → `Player.update` → `Camera.update` → `Weapon.update` → `Ranged.update` → spawner → `Enemy.update` → `Projectile.update` → `Combat.update`. Dibujo: `Map` → `Enemy` → `Weapon` → `Projectile` → `Player` → HUD → aviso de ronda / game over.

**Orden de `import` en `main.lua`:** primero `core/config`, `core/pool` y `core/collision`; las tablas de `data/` antes de los módulos que las usan al cargarse (`weapon_types` antes de `weapon`, `enemy_types` antes de `enemy`); `pool` antes de `enemy`, `projectile` y `gems` (crean su pool al cargarse). El orden exacto está en `main.lua`.

### Convenciones
- Estilo de Lua simple. El dibujo del juego se hace con `playdate.graphics` (círculos y líneas) y solo se importa `CoreLibs/graphics`. **Sí se pueden usar librerías** (las CoreLibs del SDK, como sprites, timers o animación, u otras externas) cuando aporten valor real. Antes de agregar una, propón la opción, explica qué gana y qué complica, y espera mi OK.
- Las colisiones son con matemática propia (círculos y AABB). No es una restricción: si una librería o el SDK resuelve algo mejor o más simple, se puede evaluar.
- Los objetos que aparecen y desaparecen muchas veces (enemigos, proyectiles) van en un pool, para no generar basura en memoria. Al reutilizar un objeto hay que reiniciar todos sus campos.
- `math.random(m, n)` necesita enteros: si los límites vienen de la cámara (decimales), redondea con `math.floor`.
- Comentarios en español; nombres de variables y funciones en inglés, como ya está.

### Sobre requisitos técnicos
El profesor **no ha confirmado** si son obligatorios el Object Pooling, la máquina de estados (FSM) o las colisiones hechas a mano. Se usan como buenas prácticas de arquitectura. No los quites ni los extiendas de forma masiva sin consultarme.

### Arte y créditos
- El juego usa arte 1-bit: la pantalla del Playdate es solo blanco y negro puro. Las imágenes deben convertirse a 1-bit (con transparencia si van encima de otras cosas).
- El pasto, el camino de grava y la farola salen del tileset gratuito "GameBoy-styled essential outdoor tiles" de **chuckiecatt** (itch.io), convertido a blanco y negro. **Hay que dar crédito a chuckiecatt en el juego final.** Los árboles, enemigos, gemas y armas los generé con código (scripts en `arte/herramientas/`).
- **Organización:** `source/images/` solo debe tener lo que el juego usa (todo lo que está ahí se empaqueta en el juego). Los diseños descartados o guardados para después están en `arte/` (fuera de `source/`): `arte/enemigos/`, `arte/armas/`. Los dibujos de las armas miran hacia arriba y el juego los gira.
- **Armas guardadas (diseñadas, no usadas todavía)** en `arte/armas/`: `maza` (ya definida como `MAZA` en `weapon_types.lua`, con dibujo en `source/images/`), `hacha`, `martillo`, `espada` (la primera, gruesa) y las espadas `espada_estoque`, `espada_katana`, `espada_cimitarra` (`espada_larga` es el arma inicial y `espada_mandoble` está definida como `MANDOBLE`). Para dejar una disponible: copiar el dibujo a `source/images/weapon_nombre.png`, agregar su entrada en `weapon_types.lua` (con `HITBOXES` a lo largo de su forma, `ROTATE`/`NO_CHAIN` si aplica) y ofrecerla en `upgrades.lua`. Las hitbox se revisan con `Config.DEBUG_HITBOXES = true`.

---

## Diseño previsto

Ya implementado: rondas, tipos de arma, pistola, mapa infinito con cámara, gemas de XP y niveles con menú de mejoras (RF-07 a RF-13). La pistola ya no se desbloquea en la ronda 2: se consigue como una mejora (una sola vez) al subir de nivel. **Abierto:** si más adelante habrá tienda (como Brotato) o si bastará con que armas y estadísticas salgan en el menú de nivel (como Vampire Survivors). Más armas y subir de nivel las armas quedan para la iteración 4; ojo que hoy cada enemigo tiene un solo temporizador de golpe compartido por todas las armas cuerpo a cuerpo, habría que darle uno a cada arma.

- **Mapa más vistoso (en evaluación, rama de experimento):** reemplazar la grilla de puntos por un tile de pasto 1-bit y agregar decoraciones (árboles, farolas) repartidas de forma fija y poco frecuente por el mundo infinito. Pendiente: hacer el pasto más grande (dibujarlo escalado) y definir cómo se reparten las decoraciones. Aún no es parte del plan oficial.
- **Fuera del MVP (deseables):** dificultad creciente, menú de inicio y pantalla de victoria, tienda y monedas, más tipos de enemigos y armas, sonido y arte final.
- **Ya definido en el GDD v0.4 (docs en Google Docs / `.docx`):** XP y subida de nivel automática (sección 5), 3 tipos de enemigo (básico, rápido, tanque), 4-5 armas (espada, maza, lanza, pistola, escopeta, lanzallamas), tienda entre rondas con monedas. El profesor ya sabe que veremos experiencia y UI.
- **Decisiones recientes:** mundo infinito (mezcla de Brotato, con rondas y tienda, y Vampire Survivors, con mundo que se desplaza y recolección de gemas). Idea aprobada: **jefe cada 5 rondas**.
- **Por confirmar:** duración de la partida. Propuesta: 10 rondas, jefe en la 5 y la 10, pantalla de victoria al ganar la 10 (como Brotato). Vampire Survivors también tiene un límite (30 min).
- **Decisión de armas (opción C, mezcla de Vampire Survivors y Brotato):** cada arma sube de nivel al volver a elegirla en el menú de nivel, y algunos niveles se manifiestan como una copia más (Pistola Nv. 2 = una segunda pistola; arma que gira Nv. 2 = una segunda arma orbitando al lado opuesto). Tope pensado: unas 3 o 4 copias por arma, porque la pantalla es de 400x240 en blanco y negro y más cosas girando se vuelve ilegible. Por ahora (RF-13) hay una sola pistola y no se repite. Para hacerlo (iteración 4) hace falta: un temporizador de golpe por arma, que cada pistola apunte a un enemigo distinto, y ángulos distintos para las armas que giran.
- **Ideas aún sin decidir:** estela en las armas con la energía al máximo; podría ser comportamiento base. La manivela como imán de gemas se probó y se descartó (por ahora las gemas solo se recogen al tocarlas); podría volver como objeto de la tienda.

---

## Plan de desarrollo

Los identificadores RF corresponden a los requisitos del documento de avance. Marca cada paso como hecho cuando yo lo confirme. Antes de empezar una funcionalidad, crea (o pídeme crear) su rama `feature/rf-XX-nombre` desde `develop`.

### RF-07 — Temporizador y rondas — hecho, mergeado a `develop`
- [x] **Paso 1.** Crear `round.lua` con un temporizador de 30 segundos que cuenta hacia atrás.
- [x] **Paso 2.** Mostrar el tiempo restante en pantalla.
- [x] **Paso 3.** Llevar el número de ronda, mostrarlo, y al llegar el tiempo a cero pasar a la ronda siguiente.
- [x] **Paso 4.** Al cambiar de ronda, quitar los enemigos vivos y mostrar un aviso breve ("Ronda N"). Al reiniciar la partida, volver a la ronda 1.

### RF-08 — Tipos de arma — hecho, mergeado a `develop`
- [x] **Paso 5.** Crear `weapon_types.lua` con la definición del arma actual.
- [x] **Paso 6.** Hacer que `weapon.lua` lea sus valores desde esa tabla.
- [x] **Paso 7.** Crear la lista de armas del jugador; `weapon.lua` y `combat.lua` recorren la lista.

### RF-09 — Arma a distancia — hecho, mergeado a `develop`
- [x] **Paso 8.** `projectile.lua` con pool, movimiento y dibujo.
- [x] **Paso 9.** `Enemy.closest(x, y)`.
- [x] **Paso 10.** `ranged.lua`: la pistola dispara sola al enemigo más cercano.
- [x] **Paso 11.** Los proyectiles dañan enemigos y desaparecen al golpear o salir de la pantalla.
- [x] **Paso 12.** La cadencia de disparo aumenta con `Energy.ratio()`.

### RF-10 — Desbloqueo de arma al avanzar de ronda — hecho, mergeado a `develop`
- [x] **Paso 13.** La pistola se desbloquea en la ronda 2 (`Ranged.UNLOCK_ROUND`); al reiniciar, vuelve al estado inicial. (Reemplazado en RF-13: ahora es una mejora del menú de nivel.)

### RF-11 — Mapa y cámara — hecho, mergeado a `develop`
Sugerido por el profesor: que el mapa se mueva, estilo Vampire Survivors. Mundo infinito; el jugador queda centrado y el mundo se desplaza.
- [x] **Paso 14.** `camera.lua` y `map.lua` (grilla de puntos), conectados en `main.lua`.
- [x] **Paso 15.** Quitar el límite de pantalla del jugador; `Player.draw()` usa la cámara.
- [x] **Paso 16.** `weapon.lua` y `projectile.lua` dibujan con la cámara (y los proyectiles se borran al salir de lo visible).
- [x] **Paso 17.** `enemy.lua` dibuja con la cámara y genera enemigos alrededor de la cámara.

### RF-12 — Fondo del mapa con tiles — hecho, mergeado a `develop`
Pasto ralo, caminos de grava que serpentean, farolas al borde de los caminos, arboledas con dos tipos de árbol y enemigos con relleno blanco (Pasos 18 a 21, ver `map.lua`).

### RF-13 — Gemas de XP y niveles (rama `feature/rf-13-xp-y-niveles`) — hecho, mergeado a `develop`
- [x] **Paso 22.** Los enemigos sueltan una gema al morir (`gems.lua`, con pool).
- [x] **Paso 23.** Las gemas se recogen y suman experiencia (`xp.lua`). Se probó un imán que las atraía (y que crecía con la manivela), pero se quitó: ahora solo se recogen al tocarlas.
- [x] **Paso 24.** Barra de XP abajo a la derecha, nivel ("Nv. N") y aviso "Nivel N" al subir.
- [x] **Paso 25.** `stats.lua`: modificadores del jugador (vida extra, velocidad, daño, energía, cadencia) que cada módulo aplica a su valor base.
- [x] **Paso 26.** `upgrades.lua` y menú al subir de nivel (el juego se pausa; arriba/abajo y A para elegir 1 de 3 mejoras al azar). Se cambió el plan: en vez de un bono automático, el jugador elige. Mejoras: Vitalidad, Fuerza, Rapidez, Carga, Punteria (solo con pistola), Pistola (arma nueva, una sola vez), Iman (alcance de recogida) y Alcance (del arma que gira). El HUD muestra la vida como actual/máxima y aparece un aviso con la mejora elegida.
- [x] Las gemas se reciclan (la más lejana) cuando el pool está lleno, para que el XP no se frene.
- [ ] Pendiente: ajustar el balance jugando (XP por nivel, tamaño de cada mejora) y definir qué pasa con las armas (subirlas de nivel, más tipos).

### RF-14 — Enemigos con tipos y dibujos (rama `feature/rf-14-enemigos-y-dificultad`) — en curso
- [x] Dibujos de 4 enemigos con 2 cuadros de animación (fantasma, murciélago, oso, araña). Se descartaron golem, slime y escarabajo (quedan en `arte/enemigos/`); el script que los genera está en `arte/herramientas/generar_enemigos.py`. El oso no convence del todo (se ve más simpático que amenazante); se puede retocar.
- [x] `enemy_types.lua`: cada enemigo tiene su tipo (tamaño, velocidad, vida, daño); `combat.lua` usa el tamaño y daño de cada uno.
- [x] Los enemigos se dibujan con sprites animados.
- [x] Murciélago (rápido, desde la ronda 2), araña (zigzag, desde la 3) y oso (tanque, desde la 4) aparecen según la ronda.
- [x] Dificultad creciente (`difficulty.lua`): el intervalo entre enemigos baja 0,07 s por ronda (mínimo 0,3 s) y su vida sube 12% por ronda. El pool de enemigos subió de 40 a 70. La pistola se bajó de cadencia (1,2 s sin energía a 0,4 s con energía llena) porque se sentía demasiado fuerte.
- [x] Jefe cada 5 rondas (`Difficulty.BOSS_EVERY`): un murciélago gigante (vida 40 más el aumento por ronda, lento, 2 de daño, suelta 12 gemas) con barra de vida encima y aviso "Ronda N - JEFE!". No está en `EnemyTypes.LIST`, se llama con `Enemy.spawnBoss()`. Se dibuja siempre encima de los demás enemigos. **Si no lo matas dentro de la ronda, sigue vivo** en la siguiente (al cambiar de ronda solo se borran los enemigos normales, `Enemy.clearNormals()`), y no aparece otro jefe mientras el anterior siga vivo. Esto funciona igual si más adelante se quitan las rondas.
- [x] `Difficulty.level()`: toda la dificultad (ritmo de aparición, vida, jefe, qué enemigos salen) depende de esta función, que hoy devuelve el número de ronda. Si se decide un estilo Vampire Survivors (sin rondas ni tienda), basta con que devuelva otra cosa (por ejemplo los minutos jugados). Decisión de fondo aún abierta: rondas con tienda (Brotato) o tiempo continuo sin tienda (Vampire Survivors).
- [x] `Config.DEBUG_HITBOXES`: poner en `true` dibuja los círculos de colisión, para revisar que los golpes coinciden con lo que se ve.
- [x] Armas con dibujo propio: el arma inicial es una espada larga (sin cadena, zona de daño en 3 círculos a lo largo de la hoja); maza con cadena y mandoble listos pero sin usar. Ver "Arte y créditos".
- [ ] Pendiente: dibujo del personaje (hoy es un círculo negro), retocar el oso, balance del jefe y de las armas.

### Hoja de ruta (la práctica termina el 20 de diciembre; reunión con el profesor cada 2 semanas)
Cada iteración = una rama y un PR, con commits atómicos por paso. El profesor pidió elegir bien qué funcionalidad mostrar en cada reunión.
1. **Mapa** (rama `experimento/tileset-mapa`, en curso): fondo con tile de pasto más grande y algunas decoraciones (árboles, farolas) repartidas de forma fija por el mundo. Es el arte lo que más tiempo consume: no gastar más de un par de pasos aquí.
2. **Stats + XP y niveles:** `stats.lua` (valores juntos), los enemigos sueltan gemas de XP (pool), el jugador las recoge, barra de XP y subida de nivel automática.
3. **Estados + monedas + tienda:** `state.lua` (menú, juego, tienda, game over, victoria), monedas, `items.lua` y `shop.lua`; las armas se compran (reemplaza el desbloqueo provisorio de la ronda 2).
4. **Contenido:** enemigos rápido y tanque (`enemy_types.lua`), dificultad creciente por ronda, jefe cada 5 rondas, más armas en `weapon_types.lua`.
5. **Pulido:** sprites 1-bit, sonido, estela de armas con energía máxima, balance, documentación final.

### Otros pendientes
- [ ] Ajuste de balance jugando (valores de energía, velocidades, daño).
- [ ] Actualizar el GDD a v0.5 y el documento "Funcionalidades en Desarrollo" (están desactualizados respecto al código).
