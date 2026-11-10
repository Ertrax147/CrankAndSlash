# Crank & Slash

Arena survival roguelite para la consola **Playdate**, escrito en Lua con el SDK nativo. Arte en 1-bit.

El personaje se mueve por un mundo infinito mientras un arma gira sola a su alrededor y los enemigos lo persiguen. La particularidad: **la manivela no apunta, carga energía**. Con más energía el arma gira más rápido y la pistola dispara más seguido; si dejas de girar, la energía baja sola y el combate sigue a ritmo mínimo.

> En desarrollo.

## Cómo se juega
- **Cruceta:** mover al personaje.
- **Manivela:** cargar la energía (gira en cualquier sentido).
- **A:** elegir en los menús y reiniciar después de morir.
- Los enemigos sueltan gemas de experiencia. Al subir de nivel el juego se pausa y eliges 1 de 3 mejoras.
- Cada ronda dura 30 segundos y la dificultad sube con cada una. Cada 5 rondas llega un jefe.

## Compilar y probar
Necesitas el [Playdate SDK](https://play.date/dev/) instalado.

```
pdc source CrankAndSlash.pdx
```

Después abre `CrankAndSlash.pdx` en el Playdate Simulator. La manivela se simula en el panel de la parte inferior del simulador.

Al abrir el juego aparece una pantalla de pruebas (personaje, ronda inicial, arma, etc.). Se desactiva poniendo `DEBUG_MENU = false` en `source/core/config.lua`.

### Prueba automática (opcional)
Ejecuta el juego sin pantalla con teclas al azar y avisa de errores de ejecución o imágenes que faltan:

```
pip install lupa
python herramientas/prueba_sin_simulador.py
```
