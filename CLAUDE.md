# Crank & Slash — contexto del proyecto

Juego para la consola **Playdate**, escrito en **Lua** con el SDK nativo. Es el proyecto de la Práctica Profesional 1 de Cristopher (Ingeniería Civil en Informática, UFRO). Género: arena survival / roguelite de acción, inspirado en Brotato. Arte 1-bit monocromático.

Para compilar y probar: `pdc source CrankAndSlash.pdx` y abrir el `.pdx` en el Playdate Simulator. La manivela se simula en el panel de la parte inferior del simulador. No hay tests automáticos: cada paso se prueba jugando en el simulador.

---

## Cómo quiero trabajar contigo (leer primero)

Estoy aprendiendo desarrollo de videojuegos y Lua, y tengo que poder explicar todo el código en las revisiones con mi profesor. Por eso:

1. **Un paso a la vez.** Trabaja solo el paso que te pida del plan (sección "Plan de desarrollo"). No adelantes pasos ni agregues funcionalidades que no pedí.
2. **Antes de escribir código**, explícame el plan en 3 a 5 líneas (qué archivos tocarás y qué harás) y espera mi confirmación.
3. **Toca lo mínimo.** No refactorices ni renombres cosas que no sean parte del paso. Si crees que algo debería reorganizarse, proponlo aparte y no lo hagas por tu cuenta.
4. **Explica en español simple** qué cambiaste y por qué, línea por línea si el cambio es nuevo. Evita jerga innecesaria.
5. **Dime cómo probarlo**: qué debo ver en el simulador si funciona bien. No puedes ejecutar el simulador, así que no afirmes que "funciona" sin decir que falta que yo lo pruebe.
6. **Git:** sigue el flujo de la sección "Flujo de trabajo con Git". Puedes ejecutar los comandos de git que yo te pida (crear ramas, commits), mostrándome cada comando antes de correrlo. No reescribas el historial ni cambies fechas de commits.
7. Si algo del diseño no está definido o tienes una duda, **pregúntame** en vez de decidir tú.

---

## Flujo de trabajo con Git

Ramas:
- `main`: versión estable, lista para mostrar al profesor. Solo recibe cambios desde `develop` cuando una etapa está probada.
- `develop`: rama de integración. Recibe las funcionalidades ya terminadas.
- `feature/rf-XX-nombre`: una rama por funcionalidad, creada desde `develop` (por ejemplo `feature/rf-07-rondas`). Todo el desarrollo ocurre aquí.

Reglas para ti (Claude Code):
1. **Al empezar cada sesión**, revisa la rama actual (`git branch --show-current`) y el estado (`git status`). Dime en qué rama estamos y si hay cambios sin guardar.
2. **Nunca edites archivos estando en `main` o `develop`.** Si estamos en una de ellas, avísame y espera a que yo cambie a la rama de la funcionalidad.
3. **Crea ramas, cambia de rama y haz commits solo cuando yo te lo pida**, mostrándome el comando antes de ejecutarlo. **Nunca hagas `push`, `merge`, `rebase` ni `push --force`** sin que yo lo pida de forma explícita en ese mensaje.
4. **Commits pequeños:** uno por paso del plan, con formato `feat:`, `fix:` o `docs:` en español y sin tildes. Al terminar un paso, sugiéreme el mensaje y espera a que yo te pida hacer el commit.
5. Cuando una funcionalidad esté terminada, ayúdame a redactar la descripción del Pull Request hacia `develop`, con los criterios de aceptación de su ficha y cómo probarla.

---

## Estado actual: núcleo de combate (implementado y probado en el simulador)

### Qué hace el juego hoy
- El personaje (círculo relleno) se mueve con la cruceta dentro de la pantalla.
- Un arma cuerpo a cuerpo gira **sola** alrededor del personaje a una velocidad base. Solo el círculo del extremo hace daño; la línea que lo une al personaje es solo visual.
- **Energía de la manivela:** girar la manivela (en cualquier sentido) carga una barra de energía. La energía baja sola con el tiempo. Cuanto más energía, más rápido gira el arma. Sin energía el arma sigue girando a velocidad base (nunca se detiene). La manivela **no apunta**: solo carga energía.
- Los enemigos (círculos sin relleno) aparecen en un borde de la pantalla, cada 1 segundo, y persiguen al jugador en línea recta.
- El arma les quita vida al tocarlos. Después de un golpe, ese enemigo no puede recibir otro del arma por 0,4 s.
- Si un enemigo toca al jugador, este pierde 1 de vida y queda 1 segundo invulnerable (parpadea).
- Si la vida llega a 0 aparece "GAME OVER"; con el botón A se reinicia.
- Pantalla: vida (texto arriba a la izquierda) y barra de energía (abajo a la izquierda).

### Provisorio (se reemplazará)
- La aparición de enemigos cada 1 s (`Config.SPAWN_INTERVAL`) es fija; debería depender de rondas.
- El reinicio con A en `main.lua` es una versión mínima; falta una máquina de estados real.

### Valores actuales (ajustables, están al inicio de cada archivo)
| Módulo | Valores |
|---|---|
| Player | radio 8, velocidad 90 px/s, vida 5, invulnerabilidad 1 s |
| Weapon | órbita 30 px, radio 6, daño 1, velocidad 120°/s (base) a 540°/s (energía llena), cooldown de golpe 0,4 s |
| Energy | máximo 100, +0,12 por grado girado, −12 por segundo |
| Enemy | radio 7, velocidad 40 px/s, vida 3, pool de 40 |
| Combat | daño por contacto al jugador: 1 |
| Config | pantalla 400x240, dt = 1/30 (30 fps) |

---

## Arquitectura

Todo el código está en `source/`. Cada archivo tiene una sola responsabilidad y se carga con `import` desde `main.lua`. Los módulos son **tablas globales** (`Config`, `Pool`, `Collision`, `Energy`, `Player`, `Weapon`, `Enemy`, `Combat`). Las constantes van en mayúsculas al inicio del módulo, sin números sueltos en el código.

| Archivo | Responsabilidad |
|---|---|
| `main.lua` | Carga todo, define `playdate.update()` (se llama ~30 veces por segundo), el HUD, el spawner provisorio y el game over |
| `config.lua` | Constantes generales (tamaño de pantalla, dt, intervalo de aparición) |
| `pool.lua` | Object Pool genérico: `Pool.new(size, factory)`, `acquire()`, `release(obj)`, `releaseAll()`. Los objetos se crean una vez y se reutilizan con el campo `active` |
| `collision.lua` | `Collision.circles(...)` (círculo contra círculo, comparando distancias al cuadrado) y `Collision.aabb(...)` (rectángulos; aún sin usar) |
| `energy.lua` | Energía de la manivela: `update(dt)`, `ratio()` (0 a 1), `reset()` |
| `player.lua` | Movimiento con cruceta, límites de pantalla, vida, invulnerabilidad, dibujo |
| `weapon.lua` | Arma cuerpo a cuerpo orbital: su velocidad depende de `Energy.ratio()` |
| `enemy.lua` | Enemigo perseguidor gestionado con un pool (`Enemy.pool`), `spawn()`, `update(dt)`, `draw()` |
| `combat.lua` | Revisa colisiones arma-enemigo y enemigo-jugador y aplica el daño |

**Orden de actualización por frame** (importa, no lo cambies sin avisar): `Energy.update` → `Player.update` → `Weapon.update` → spawner → `Enemy.update` → `Combat.update` → dibujo.

**Orden de `import` en `main.lua`:** `config`, `pool`, `collision`, `energy`, `player`, `weapon`, `enemy`, `combat`. `pool` debe ir antes de `enemy`, porque `enemy.lua` crea su pool al cargarse.

### Convenciones
- Estilo de Lua simple. Hoy el dibujo se hace con `playdate.graphics` (círculos y líneas) y solo se importa `CoreLibs/graphics`. **Sí se pueden usar librerías** (las CoreLibs del SDK, como sprites, timers o animación, u otras externas) cuando aporten valor real. Antes de agregar una, propón la opción, explica qué gana y qué complica, y espera mi OK.
- Las colisiones hoy son con matemática propia (círculos y AABB). No es una restricción: si una librería o el SDK resuelve algo mejor o más simple, se puede evaluar.
- Los objetos que aparecen y desaparecen muchas veces (enemigos, proyectiles) van en un pool, para no generar basura en memoria. Al reutilizar un objeto hay que reiniciar todos sus campos.
- Comentarios en español; nombres de variables y funciones en inglés, como ya está.

### Sobre requisitos técnicos
El profesor **no ha confirmado** si son obligatorios el Object Pooling, la máquina de estados (FSM) o las colisiones hechas a mano. Se usan como buenas prácticas de arquitectura. No los quites ni los extiendas de forma masiva sin consultarme.

---

## Diseño previsto (decidido, aún no implementado)

- **Rondas:** rondas de 30 segundos con temporizador y número de ronda visibles. Al terminar una ronda desaparecen los enemigos vivos y aparece un aviso. Las rondas continúan hasta que el jugador muere (no hay pantalla de victoria).
- **Tipos de arma:** una tabla de definiciones de armas (tipo, daño, tiempo entre golpes o cadencia, alcance) y una lista con las armas que lleva el jugador. El comportamiento del juego no cambia; solo queda preparado para agregar armas.
- **Arma a distancia:** una pistola que apunta sola al enemigo más cercano. Su cadencia de disparo aumenta con la energía de la manivela. Los proyectiles usan su propio pool.
- **Desbloqueo de arma:** el jugador empieza solo con el arma cuerpo a cuerpo y al comenzar la ronda 2 se agrega la pistola; desde ahí usa ambas a la vez. No hay botón de cambio de arma ni menús.
- **Mapa y cámara:** sugerido por el profesor. El jugador queda centrado en pantalla y el mundo se mueve (estilo Vampire Survivors). Mundo infinito, sin bordes. Fondo con una grilla simple de puntos por ahora (evaluar más adelante un tileset 1-bit importado). La lógica de juego sigue en coordenadas de mundo; solo el dibujo se convierte a pantalla mediante la cámara.
- **Fuera del MVP (deseables):** dificultad creciente, menú de inicio y pantalla de victoria, tienda y monedas, más tipos de enemigos y armas, sonido y arte final.
- **Por definir con el profesor:** experiencia y subida de nivel, y un segundo tipo de enemigo. No las implementes hasta que yo lo confirme.

---

## Plan de desarrollo (pasos pequeños, en este orden)

Los identificadores RF corresponden a los requisitos del documento de avance. Marca cada paso como hecho cuando yo lo confirme. Un paso = un cambio pequeño y probable = un commit. Antes de empezar una funcionalidad, crea (o pídeme crear) su rama `feature/rf-XX-nombre` desde `develop`.

### RF-07 — Temporizador y rondas (rama `feature/rf-07-rondas`) — hecho, mergeado a develop
- [x] **Paso 1.** Crear `round.lua` con un temporizador de 30 segundos que cuenta hacia atrás (aún sin mostrarlo).
- [x] **Paso 2.** Mostrar el tiempo restante en pantalla.
- [x] **Paso 3.** Llevar el número de ronda, mostrarlo, y al llegar el tiempo a cero pasar a la ronda siguiente reiniciando el temporizador.
- [x] **Paso 4.** Al cambiar de ronda, quitar los enemigos vivos y mostrar un aviso breve ("Ronda N"). Al reiniciar la partida, volver a la ronda 1.

### RF-08 — Tipos de arma (rama `feature/rf-08-tipos-de-arma`) — hecho, mergeado a develop
- [x] **Paso 5.** Crear `weapon_types.lua` con la definición del arma actual (daño, radio, tiempo entre golpes, velocidades), sin cambiar el comportamiento.
- [x] **Paso 6.** Hacer que `weapon.lua` lea sus valores desde esa tabla en vez de tenerlos escritos.
- [x] **Paso 7.** Crear la lista de armas del jugador: `weapon.lua` actualiza y dibuja cada arma de la lista, y `combat.lua` revisa el daño de cada una. Con una sola arma el juego debe verse igual que antes.

### RF-09 — Arma a distancia (rama `feature/rf-09-arma-a-distancia`) — hecho, mergeado a develop
- [x] **Paso 8.** Crear `projectile.lua` con su pool, movimiento y dibujo (probar con un proyectil de prueba).
- [x] **Paso 9.** Agregar en `enemy.lua` una función que devuelva el enemigo activo más cercano al jugador.
- [x] **Paso 10.** Crear `ranged.lua`: la pistola dispara sola cada cierto tiempo hacia el enemigo más cercano.
- [x] **Paso 11.** Los proyectiles dañan enemigos (círculo contra círculo) y desaparecen al golpear o salir de la pantalla.
- [x] **Paso 12.** La cadencia de disparo aumenta con `Energy.ratio()`.

### RF-10 — Desbloqueo de arma al avanzar de ronda (rama `feature/rf-10-desbloqueo-de-arma`) — hecho, mergeado a develop
- [x] **Paso 13.** Empezar solo con el arma cuerpo a cuerpo y agregar la pistola a la lista al comenzar la ronda 2. Al reiniciar la partida, volver al estado inicial.

### RF-11 — Mapa y cámara (rama `feature/rf-11-mapa-y-camara`) — hecho, falta mergear a develop
Sugerido por el profesor en la reunión de avance: que el mapa se mueva, estilo Vampire Survivors. El jugador queda centrado en la pantalla y es el mundo el que se desplaza. Mundo infinito (sin bordes). El fondo es una grilla simple de puntos (mas adelante se podria reemplazar por un tileset 1-bit importado, sin tocar el resto del codigo). La logica de juego (movimiento, colisiones, dano) sigue funcionando en coordenadas de mundo sin cambios; solo el dibujo convierte de mundo a pantalla restando la posicion de la camara.
- [x] **Paso 14.** Crear `camera.lua` (`Camera.x/y`, `Camera.update()` sigue al jugador, `Camera.toScreen(worldX, worldY)`) y `map.lua` (grilla de puntos de fondo dibujada con `Camera.toScreen`). Conectar ambos en `main.lua`.
- [x] **Paso 15.** Quitar el límite de pantalla en `player.lua` (mundo infinito) y hacer que `Player.draw()` use `Camera.toScreen`. El jugador queda siempre centrado.
- [x] **Paso 16.** Actualizar `weapon.lua` y `projectile.lua` (solo sus funciones `draw()`) para usar `Camera.toScreen`.
- [x] **Paso 17.** Actualizar `enemy.lua`: `draw()` usa `Camera.toScreen`, y `spawn()` genera enemigos en un borde alrededor de la cámara en vez de bordes fijos de la pantalla.

### Después
- [ ] Ajuste de balance jugando (valores de energía, velocidades, daño).
- [ ] Definir con el profesor: experiencia y niveles, segundo tipo de enemigo.
- [ ] Deseables (dificultad creciente, menú y victoria, tienda, más contenido, sonido, arte).
