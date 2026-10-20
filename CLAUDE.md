# Crank & Slash — instrucciones para Claude Code

Juego para la consola **Playdate**, escrito en **Lua** con el SDK nativo: arena survival / roguelite de acción en arte 1-bit, inspirado en Brotato y Vampire Survivors. Es un proyecto de práctica universitaria (Práctica Profesional 1, hasta el 20 de diciembre de 2026). La idea central: **la manivela no apunta, carga energía** (más energía = el arma gira más rápido y la pistola dispara más seguido).

Este repositorio es **público**: el código y el README. Las notas, el GDD, el plan y las decisiones viven en otro repo, privado (ver "Documentación").

## Documentación
- `README.md`: qué es el juego, cómo compilarlo y jugarlo.
- **Repo privado de docs** (`CrankAndSlash-docs`), que debe estar clonado **al lado** de este: `../CrankAndSlash-docs`. Ahí están `ARQUITECTURA.md` (cómo está hecho el código, con más detalle que este archivo), `PLAN.md` (RF y pendientes), el GDD y las decisiones. Si hace falta contexto del proyecto, léelo desde ahí. Si la carpeta no existe en este PC, dilo y propón clonarla.
- **"Revisa mi carpeta de docs y sube la actualización":** esa frase pide guardar y subir los documentos. Ve a `../CrankAndSlash-docs`, **lee primero su `CLAUDE.md`** y sigue sus pasos (ahí está el permiso de push para ese repo).
- No copies contenido del repo privado a este repo público sin que se pida.

## Cómo trabajar
Se trabaja en pasos pequeños, porque el autor debe poder entender y explicar todo el código en sus revisiones.
1. **Un paso a la vez.** Haz el paso que se pide; si dos pasos son tan chicos que no tienen nada que probar por separado, puedes juntarlos avisando. No agregues funcionalidades que no se pidieron.
2. **Antes de escribir código, explica el plan** en 3 a 5 líneas (qué archivos tocarás y qué harás) y espera confirmación. Para cambios muy chicos y claros (ajustar un valor, una corrección ya acordada) puedes avanzar y explicar después.
3. **Toca lo mínimo.** No refactorices ni renombres lo que no sea parte del paso; si crees que algo debería reorganizarse, propónlo aparte. Si un cambio obliga a tocar algo fuera del paso, avisa y explica por qué antes.
4. **Explica en español simple**, sin jerga innecesaria, qué cambiaste y por qué.
5. **Di cómo probarlo** en el simulador. No puedes ejecutar el simulador: no afirmes que algo "funciona" sin aclarar que falta probarlo ahí.
6. **Comentarios:** cada función nueva lleva una línea arriba explicando qué hace, más una nota dentro si algo no es obvio (el porqué). No comentes línea por línea.
7. Si algo del diseño no está definido o hay duda, **pregunta** en vez de decidir.

## Flujo de trabajo con Git
Ramas:
- `main`: versión estable. Solo recibe cambios desde `develop` cuando una etapa está probada.
- `develop`: integración. Recibe las funcionalidades terminadas.
- `feature/rf-XX-nombre`: una por funcionalidad, creada desde `develop`. Todo el desarrollo ocurre aquí.
- `docs/nombre`: cambios solo de documentación, desde `develop`.
- `refactor/nombre`: reorganizaciones sin cambiar cómo se juega.
- `experimento/nombre`: pruebas sin compromiso; no se mergean a `develop` sin hablarlo.

Reglas:
1. **Al empezar cada sesión**, revisa la rama actual (`git branch --show-current`) y el estado (`git status`), y avisa en qué rama estamos y si hay cambios sin guardar.
2. **Nunca edites archivos estando en `main` o `develop`.** Si estamos en una de ellas, avisa y espera.
3. **Crea ramas y cambia de rama solo cuando se pida**, mostrando el comando antes. **Nunca hagas `push`, `merge`, `rebase` ni `push --force`** sin que se pida de forma explícita en ese mensaje. Antes de cualquier comando que pueda descartar trabajo (`restore`, `clean`, `reset`, borrar carpetas o ramas), revisa `git status` y avisa qué se perdería.
4. **Commits pequeños**, uno por paso del plan (o por grupo de pasos muy chicos), con formato `feat:`, `fix:`, `docs:` o `refactor:`, en español y **sin tildes ni eñes**. Haz el commit local apenas termines cada paso, sin pedir confirmación (no sube nada y se puede corregir). El autor prueba por tandas: al terminar una, di qué probar. Si algo falla, corrige con un commit `fix:`.
5. **No agregues** líneas `Co-Authored-By` ni "Generated with Claude Code" en commits ni en PRs.
6. **Los Pull Requests los crea y mergea el autor** desde GitHub. No ejecutes `gh pr create` ni `gh pr merge` (`gh` sirve solo para consultar estados). Cuando una funcionalidad esté terminada y se pida subirla, haz el `push` y entrega el link de comparación (`https://github.com/Ertrax147/CrankAndSlash/compare/develop...rama`) con el título y la descripción del PR.
7. **Formato del PR** (mira los últimos PRs con `gh pr view` si hay duda): título `RF-NN: Título` (o `docs:` / `refactor:` según el caso); descripción de **un solo párrafo** que explica qué hace, y luego `**Criterios de aceptación:**` con una lista de casillas. **Sin** sección "cómo probarlo" ni encabezados. Marca `[x]` solo lo que se verificó de verdad.
8. Después de que se mergee un PR, trae los cambios (`git checkout develop` y `git pull`) y recién ahí crea la rama de lo siguiente.

## Arquitectura (resumen)
Todo el código está en `source/`, en carpetas por responsabilidad. Los módulos son **tablas globales** (`Config`, `Player`, `Enemy`, `Combat`…) cargadas con `import "carpeta/archivo"` **solo desde `main.lua`**. El detalle y la guía para agregar enemigos, armas, mejoras y personajes están en `ARQUITECTURA.md` del repo de docs.

| Carpeta | Contenido |
|---|---|
| `core/` | `config`, `pool` (Object Pool genérico), `collision` (círculos y AABB propios) |
| `world/` | `camera`, `map` (mundo infinito: el contenido de cada celda sale de un hash determinista) |
| `data/` | tablas de valores sin lógica: `enemy_types`, `weapon_types`, `upgrades`, `characters` |
| `entities/` | `player`, `enemy`, `weapon`, `projectile`, `gems` |
| `systems/` | `combat`, `difficulty`, `round`, `xp`, `stats`, `energy`, `ranged`, `spawner` |
| `ui/` | `hud`, `notices`, `level_menu`, `debug`, `test_menu` (pantalla de pruebas) |
| `images/` | solo lo que el juego usa, en subcarpetas (`map/`, `enemies/`, `weapons/`, `gems/`, `player/`); lo demás va en `arte/` (fuera de `source/`) |

- **Idea clave de la cámara:** toda la lógica (movimiento, colisiones, daño) trabaja en **coordenadas de mundo**; solo el dibujo convierte con `Camera.toScreen`. Cualquier cosa que necesite saber "si está en pantalla" debe convertir con la cámara.
- **Datos vs. comportamiento:** lo que solo cambia en valores es una fila en `data/`; un archivo propio solo si el comportamiento es distinto (la pistola tiene `ranged.lua`).
- **Orden de actualización por frame** (importa, no lo cambies sin avisar), en `playdate.update()`: `LevelMenu` abierto → solo el menú (pausa); si no, `Energy` → `Round` (si empieza ronda: `Spawner.newRound()` y aviso) → `Notices` → `Player` → `Camera` → `Weapon` → `Ranged` → `Spawner` → `Enemy` → `Projectile` → `Combat` → `Gems` → detectar nivel y muerte → abrir el menú de nivel. Dibujo: `Map` → `Gems` → `Enemy` → `Weapon` → `Projectile` → `Player` → HUD → avisos → menú de nivel.
- **Orden de `import` en `main.lua`:** `core/` primero; las tablas de `data/` antes de los módulos que las usan al cargarse (`characters` antes de `player`, `weapon_types` antes de `weapon`, `enemy_types` antes de `enemy`); `pool` antes de `enemy`, `projectile` y `gems`.
- **Pantalla de pruebas:** con `Config.DEBUG_MENU = true`, al abrir el juego aparece `ui/test_menu.lua` para elegir personaje, ronda inicial, arma, etc. Poner `false` para jugar normal.

## Convenciones
- Lua simple. Dibujo con `playdate.graphics`. **Se pueden usar librerías** (las CoreLibs del SDK u otras) cuando aporten valor real, pero antes propón la opción, explica qué gana y qué complica, y espera confirmación.
- Colisiones con matemática propia (círculos y AABB). No es una restricción: si el SDK resuelve algo mejor, se puede evaluar.
- Los objetos que aparecen y desaparecen muchas veces (enemigos, proyectiles, gemas) van en un pool. Al reutilizar un objeto hay que reiniciar **todos** sus campos.
- Constantes en mayúsculas al inicio del módulo; sin números sueltos en el código.
- `math.random(m, n)` necesita enteros: si los límites son decimales, redondea con `math.floor`. En Lua 5.4 de Playdate los enteros son de 32 bits: cuidado con constantes grandes en hashes.
- Comentarios en español; nombres de variables y funciones en inglés.
- El Object Pooling, la máquina de estados y las colisiones propias se usan como buenas prácticas, pero **no se sabe si son obligatorios**: no los quites ni los extiendas de forma masiva sin consultar.

## Compilar y probar
- Compilar: `pdc source CrankAndSlash.pdx` y abrir el `.pdx` en el Playdate Simulator (la manivela se simula en el panel inferior). Si `pdc` no está en el PATH, está en `$PLAYDATE_SDK_PATH/bin/pdc.exe`.
- **Prueba sin simulador:** `python herramientas/prueba_sin_simulador.py` (necesita `pip install lupa`). Juega miles de cuadros con teclas al azar y avisa de errores de ejecución o imágenes que faltan, que el compilador no detecta. Corre después de cada cambio de código. No reemplaza probar jugando: no juzga cómo se ve ni cómo se siente.

## Arte y créditos
- El juego es 1-bit (blanco y negro puro): las imágenes se convierten a 1-bit, con transparencia si van encima de otras cosas.
- El pasto, el camino de grava y la farola salen del tileset gratuito "GameBoy-styled essential outdoor tiles" de **chuckiecatt** (itch.io), convertido a blanco y negro. **Hay que dar crédito a chuckiecatt en el juego final.** El resto del arte (árboles, enemigos, gemas, armas, personajes) se genera con scripts en `arte/herramientas/`.
- `source/images/` solo debe tener lo que el juego usa (todo lo que está ahí se empaqueta). Los diseños descartados o guardados para después están en `arte/`.
- Los dibujos de las armas miran hacia arriba y el juego los gira. Las hitbox se revisan con `Config.DEBUG_HITBOXES = true`.
