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
3. **Crea ramas, cambia de rama y haz commits solo cuando yo te lo pida**, mostrándome el comando antes de ejecutarlo. **Nunca hagas `push`, `merge`, `rebase` ni `push --force`** sin que yo lo pida de forma explícita en ese mensaje. Antes de cualquier comando que pueda descartar trabajo (`git restore`, `git clean`, `git reset`, borrar carpetas), revisa `git status` y avísame qué se perdería.
4. **Commits pequeños:** uno por paso del plan (o por grupo de pasos muy chicos), con formato `feat:`, `fix:` o `docs:` en español y sin tildes ni eñes. Al terminar un paso, sugiéreme el mensaje y espera a que yo te pida hacer el commit. Haz commit de cada paso apenas yo lo confirme, para no acumular trabajo sin guardar.
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
- **Enemigos** (círculos sin relleno): aparecen justo afuera del borde visible de la pantalla, cada 1 s, y persiguen al jugador en línea recta.
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
| Weapon (`WeaponTypes.MELEE`) | órbita 30 px, radio 6, daño 1, velocidad 120°/s (base) a 540°/s (energía llena), cooldown de golpe 0,4 s |
| Ranged | cooldown de disparo 1,0 s (sin energía) a 0,2 s (energía llena), se desbloquea en la ronda 2 |
| Projectile | radio 3, velocidad 220 px/s, daño 1, pool de 20 |
| Energy | máximo 100, +0,12 por grado girado, −12 por segundo |
| Enemy | radio 7, velocidad 40 px/s, vida 3, pool de 40 |
| Round | duración 30 s, aviso de 1,5 s |
| Map | puntos cada 40 px (coordenadas de mundo), radio 1 |
| Combat | daño por contacto al jugador: 1 |
| Config | pantalla 400x240, dt = 1/30 (30 fps) |

---

## Arquitectura

Todo el código está en `source/`. Cada archivo tiene una sola responsabilidad y se carga con `import` desde `main.lua`. Los módulos son **tablas globales** (`Config`, `Pool`, `Collision`, `Energy`, `Round`, `Player`, `Camera`, `Map`, `WeaponTypes`, `Weapon`, `Enemy`, `Projectile`, `Ranged`, `Combat`). Las constantes van en mayúsculas al inicio del módulo, sin números sueltos en el código.

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
| `weapon_types.lua` | Tabla de definiciones de armas (`WeaponTypes.MELEE`: daño, radio, velocidades, cooldown) |
| `weapon.lua` | Lista de armas del jugador (`Weapon.list`). Hoy solo la cuerpo a cuerpo orbital, cuya velocidad depende de `Energy.ratio()` |
| `enemy.lua` | Enemigo perseguidor con pool (`Enemy.pool`), `spawn()` (alrededor de la cámara), `closest(x, y)`, `update(dt)`, `draw()` |
| `projectile.lua` | Proyectiles de la pistola con su propio pool: `spawn`, `update` (se liberan al salir de pantalla), `draw` |
| `ranged.lua` | La pistola: dispara sola al enemigo más cercano; cadencia según energía; se desbloquea en `UNLOCK_ROUND` |
| `combat.lua` | Revisa colisiones arma-enemigo, proyectil-enemigo y enemigo-jugador y aplica el daño |

**Idea clave de la cámara:** toda la lógica (movimiento, colisiones, daño) trabaja en **coordenadas de mundo**; solo el dibujo convierte a pantalla con `Camera.toScreen`. Por eso `collision.lua` y `combat.lua` no dependen de la cámara. Cualquier cosa que necesite saber "si está dentro de la pantalla" (como borrar proyectiles) debe convertir con la cámara, no comparar contra `Config.SCREEN_W/H` directo.

**Orden de actualización por frame** (importa, no lo cambies sin avisar): `Energy.update` → `Round.update` (si empieza ronda nueva: `Enemy.reset` y aviso) → `Player.update` → `Camera.update` → `Weapon.update` → `Ranged.update` → spawner → `Enemy.update` → `Projectile.update` → `Combat.update`. Dibujo: `Map` → `Enemy` → `Weapon` → `Projectile` → `Player` → HUD → aviso de ronda / game over.

**Orden de `import` en `main.lua`:** `config`, `pool`, `collision`, `energy`, `round`, `player`, `camera`, `map`, `weapon_types`, `weapon`, `enemy`, `projectile`, `ranged`, `combat`. `pool` debe ir antes de `enemy` y `projectile` (crean su pool al cargarse) y `weapon_types` antes de `weapon`.

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
- Rama `experimento/tileset-mapa`: prueba con el tileset gratuito "GameBoy-styled essential outdoor tiles" de **chuckiecatt** (itch.io), convertido a blanco y negro. **Si se usa en el juego final, hay que dar crédito a chuckiecatt.** Los recortes (pasto, árbol, farola) están en `source/images/`.

---

## Diseño previsto

Ya implementado: rondas, tipos de arma, pistola, desbloqueo de arma en la ronda 2, mapa infinito con cámara (RF-07 a RF-11). **Ojo:** que la pistola se desbloquee en la ronda 2 es provisorio (para probar dos armas en el prototipo); en el diseño final las armas se compran en la tienda.

- **Mapa más vistoso (en evaluación, rama de experimento):** reemplazar la grilla de puntos por un tile de pasto 1-bit y agregar decoraciones (árboles, farolas) repartidas de forma fija y poco frecuente por el mundo infinito. Pendiente: hacer el pasto más grande (dibujarlo escalado) y definir cómo se reparten las decoraciones. Aún no es parte del plan oficial.
- **Fuera del MVP (deseables):** dificultad creciente, menú de inicio y pantalla de victoria, tienda y monedas, más tipos de enemigos y armas, sonido y arte final.
- **Ya definido en el GDD v0.4 (docs en Google Docs / `.docx`):** XP y subida de nivel automática (sección 5), 3 tipos de enemigo (básico, rápido, tanque), 4-5 armas (espada, maza, lanza, pistola, escopeta, lanzallamas), tienda entre rondas con monedas. El profesor ya sabe que veremos experiencia y UI.
- **Decisiones recientes:** mundo infinito (mezcla de Brotato, con rondas y tienda, y Vampire Survivors, con mundo que se desplaza y recolección de gemas). Idea aprobada: **jefe cada 5 rondas**.
- **Por confirmar:** duración de la partida. Propuesta: 10 rondas, jefe en la 5 y la 10, pantalla de victoria al ganar la 10 (como Brotato). Vampire Survivors también tiene un límite (30 min).
- **Ideas aún sin decidir:** la manivela como imán de gemas (a más energía, más alcance) y estela en las armas con la energía al máximo; podrían ser objetos de la tienda o comportamiento base.

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
- [x] **Paso 13.** La pistola se desbloquea en la ronda 2 (`Ranged.UNLOCK_ROUND`); al reiniciar, vuelve al estado inicial.

### RF-11 — Mapa y cámara — hecho, mergeado a `develop`
Sugerido por el profesor: que el mapa se mueva, estilo Vampire Survivors. Mundo infinito; el jugador queda centrado y el mundo se desplaza.
- [x] **Paso 14.** `camera.lua` y `map.lua` (grilla de puntos), conectados en `main.lua`.
- [x] **Paso 15.** Quitar el límite de pantalla del jugador; `Player.draw()` usa la cámara.
- [x] **Paso 16.** `weapon.lua` y `projectile.lua` dibujan con la cámara (y los proyectiles se borran al salir de lo visible).
- [x] **Paso 17.** `enemy.lua` dibuja con la cámara y genera enemigos alrededor de la cámara.

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
