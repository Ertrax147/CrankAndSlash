# Prueba automatica del juego SIN el simulador de Playdate.
# Ejecuta el codigo Lua real de source/ con un "playdate" falso (no dibuja nada) y juega miles de
# cuadros con teclas y manivela al azar, forzando subidas de nivel, cambios de ronda y jefes.
# Detecta errores de ejecucion (nombres mal escritos, valores nulos...) e imagenes que faltan, cosas
# que el compilador pdc NO detecta. No reemplaza probar jugando: no puede juzgar si algo "se ve bien".
#
# Uso, desde la raiz del repositorio:   python herramientas/prueba_sin_simulador.py
# Necesita:                              pip install lupa
import os
import random
import sys

from lupa import LuaRuntime

SOURCE = "source"
FRAMES_PER_RUN = 4000
SEEDS = (1, 2, 3)

LUA_STUBS = r"""
Harness = { missing = {} }
local function noop() end

local Image = {}
Image.__index = Image
function Image:draw() end
function Image:drawRotated() end
function Image:getSize() return 16, 16 end
function Image:scaledImage() return self end

local gfx = {
    kColorBlack = 0, kColorWhite = 1, kImageUnflipped = 0, kImageFlippedX = 1,
    setColor = noop, fillRect = noop, drawRect = noop, drawText = noop, drawLine = noop,
    fillCircleAtPoint = noop, setLineWidth = noop, drawCircleAtPoint = noop, fillPolygon = noop, clear = noop,
    getTextSize = function(text) return #text * 7, 18 end,
}
gfx.image = {
    new = function(path)
        if python_file_exists(path) then return setmetatable({}, Image) end
        Harness.missing[#Harness.missing + 1] = path
        return nil -- igual que el Playdate real cuando falta una imagen
    end,
}

Input = { held = {}, pressed = {}, crank = 0 }
playdate = {
    graphics = gfx,
    kButtonUp = 1, kButtonDown = 2, kButtonLeft = 4, kButtonRight = 8, kButtonA = 16, kButtonB = 32,
    getCrankChange = function() return Input.crank end,
    buttonIsPressed = function(b) return Input.held[b] or false end,
    buttonJustPressed = function(b) return Input.pressed[b] or false end,
}

function import(name)
    if name:sub(1, 9) == "CoreLibs/" then return end
    local chunk = assert(loadfile(SOURCE_DIR .. "/" .. name .. ".lua"))
    chunk()
end

function Harness.setInput(up, down, left, right, a, crank)
    Input.held = { [1] = up, [2] = down, [4] = left, [8] = right }
    Input.pressed = { [1] = up, [2] = down, [16] = a }
    Input.crank = crank
end

function Harness.frame()
    local ok, err = xpcall(playdate.update, debug.traceback)
    return ok, err
end

function Harness.load(name)
    local ok, err = xpcall(function() import(name) end, debug.traceback)
    return ok, err
end
"""


def make_runtime(seed):
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.globals().python_file_exists = lambda path: os.path.exists(f"{SOURCE}/{path}.png")
    lua.globals().SOURCE_DIR = SOURCE
    lua.execute(LUA_STUBS)
    lua.execute(f"math.randomseed({seed})")
    return lua


def run(seed, debug_hitboxes):
    rnd = random.Random(seed)
    lua = make_runtime(seed)
    ok, err = lua.eval("Harness.load('main')")
    if not ok:
        return f"error al cargar main.lua: {err}"
    if debug_hitboxes:
        lua.execute("Config.DEBUG_HITBOXES = true")

    up = down = left = right = False
    stats = {"niveles": 0, "rondas": 0, "jefes": 0, "muertes": 0, "menu_abierto": 0}
    last_round = 1
    for frame in range(FRAMES_PER_RUN):
        if frame % 25 == 0:  # cambia de direccion cada tanto
            up, down, left, right = (rnd.random() < 0.4 for _ in range(4))
        menu_open = lua.eval("LevelMenu.isOpen()")
        game_over = lua.eval("Player.hp <= 0")
        # con el menu abierto o en game over se aprieta A de vez en cuando; en el menu tambien arriba/abajo
        press_a = (menu_open or game_over) and rnd.random() < 0.15
        crank = rnd.choice((0, 0, 5, 20, -15))
        lua.eval(f"Harness.setInput({str(up).lower()}, {str(down).lower()}, {str(left).lower()}, "
                 f"{str(right).lower()}, {str(press_a).lower()}, {crank})")

        # cambia de personaje jugable cada tanto, para probar los dibujos y datos de todos
        if frame % 500 == 0:
            lua.execute(f"Player.setCharacter(Characters.LIST[({frame // 500} + {seed}) % #Characters.LIST + 1])")

        # empujones para llegar rapido a situaciones raras
        if frame % 150 == 0:
            lua.execute("if Xp and not LevelMenu.isOpen() then Xp.add(Xp.needed() * 2) end")  # sube 2 niveles
        if frame % 200 == 100:
            lua.execute("Round.timeLeft = 0.01")  # fuerza el cambio de ronda
        if frame % 400 == 0:
            lua.execute("Energy.value = Energy.MAX")

        ok, err = lua.eval("Harness.frame()")
        if not ok:
            return f"error en el cuadro {frame}: {err}"

        if menu_open:
            stats["menu_abierto"] += 1
        if game_over:
            stats["muertes"] += 1
        round_now = lua.eval("Round.number")
        if round_now != last_round:
            stats["rondas"] += 1
            last_round = round_now
        if lua.eval("Enemy.bossAlive()"):
            stats["jefes"] += 1
        stats["niveles"] = lua.eval("Xp.level")

    missing = list(lua.eval("Harness.missing").values()) if lua.eval("#Harness.missing") > 0 else []
    if missing:
        return f"imagenes que faltan: {missing}"
    print(f"   semilla {seed}{' (con hitbox)' if debug_hitboxes else ''}: ok "
          f"- nivel final {stats['niveles']}, {stats['rondas']} cambios de ronda, "
          f"{stats['jefes']} cuadros con jefe vivo, {stats['menu_abierto']} cuadros con menu abierto, "
          f"{stats['muertes']} cuadros en game over")
    return None


def main():
    print(f"Probando el juego sin simulador ({FRAMES_PER_RUN} cuadros por corrida, Lua {LuaRuntime().eval('_VERSION')})...")
    failures = 0
    for seed in SEEDS:
        for debug_hitboxes in (False, True):
            problem = run(seed, debug_hitboxes)
            if problem:
                failures += 1
                print(f"   semilla {seed}: FALLO -> {problem}")
    print("RESULTADO:", "TODO OK" if failures == 0 else f"{failures} corrida(s) con errores")
    sys.exit(1 if failures else 0)


if __name__ == "__main__":
    main()
