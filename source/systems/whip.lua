-- Latigo: cada cierto tiempo da un golpe que se estira hacia el lado al que mira el jugador y se
-- retrae. Mas energia de la manivela = golpes mas seguidos (igual que la pistola). Su zona de dano
-- son circulos a lo largo del latigo (Whip.hits); mientras no hay golpe en curso, no hay ninguno.
local gfx = playdate.graphics

Whip = {
    BASE_COOLDOWN = 1.6,  -- segundos entre golpes sin energia
    MIN_COOLDOWN = 0.6,   -- segundos entre golpes con energia llena
    SWING_TIME = 0.25,    -- cuanto dura un golpe (se estira y se retrae)
    LENGTH = 70,          -- alcance maximo en pixeles (la mejora "Alcance" lo aumenta)
    SWEEP_DEGREES = 40,   -- cuanto baja la punta durante el golpe (de arriba hacia abajo)
    BEND = 6,             -- cuanto se curva el cuerpo del latigo hacia arriba, en pixeles
    HIT_RADIUS = 6,       -- radio de cada circulo de dano
    HIT_SPACING = 10,     -- distancia entre un circulo de dano y el siguiente
    DRAW_SEGMENTS = 6,    -- en cuantos tramos se dibuja la curva del latigo
}

-- El latigo empieza apagado: el jugador lo consigue como una mejora al subir de nivel (Upgrades),
-- que enciende Whip.unlocked.
Whip.startUnlocked = false -- true: la partida empieza con el latigo (la pantalla de pruebas lo puede cambiar)

function Whip.reset()
    Whip.unlocked = Whip.startUnlocked
    Whip.cooldown = 0   -- tiempo que falta para el proximo golpe
    Whip.timer = 0      -- tiempo que le queda al golpe en curso (0 = no hay golpe)
    Whip.swingId = 0    -- numero del golpe en curso; cada enemigo recuerda el ultimo que lo golpeo
    Whip.side = 1       -- 1 = golpea a la derecha, -1 = a la izquierda
    Whip.ext = 0        -- cuanto esta estirado ahora (pixeles)
    Whip.theta = 0      -- angulo actual del golpe (radianes; positivo = hacia abajo)
    Whip.hits = Whip.hits or {} -- circulos de dano {x, y, r}; se crean una vez y se reutilizan
    Whip.hitCount = 0   -- cuantos de Whip.hits estan en uso este cuadro
end

-- Punto del latigo (en coordenadas de mundo) a la fraccion f de su largo actual: 0 es el jugador y
-- 1 la punta. Se curva un poco hacia arriba, como si el cuerpo fuera detras de la punta.
local function pointAt(f)
    local x = Player.x + Whip.side * math.cos(Whip.theta) * Whip.ext * f
    local y = Player.y + math.sin(Whip.theta) * Whip.ext * f - Whip.BEND * math.sin(math.pi * f)
    return x, y
end

-- Empieza un golpe nuevo hacia el lado que mira el jugador
local function startSwing()
    Whip.swingId = Whip.swingId + 1
    Whip.side = Player.facingLeft and -1 or 1
    Whip.timer = Whip.SWING_TIME
    -- igual que Ranged.update: mas energia, menos espera entre golpes
    Whip.cooldown = Whip.BASE_COOLDOWN - (Whip.BASE_COOLDOWN - Whip.MIN_COOLDOWN) * Energy.ratio()
end

-- Calcula cuanto esta estirado el latigo y hacia donde apunta, segun cuanto lleva el golpe, y coloca
-- los circulos de dano a lo largo de su curva.
local function placeHits()
    if Whip.timer <= 0 then
        Whip.ext = 0
        Whip.hitCount = 0
        return
    end
    local progress = 1 - Whip.timer / Whip.SWING_TIME -- 0 al empezar, 1 al terminar
    -- se estira rapido (llega al maximo cerca del 30% del golpe) y se retrae mas despacio
    local maxLength = Whip.LENGTH * Stats.reachMult
    Whip.ext = maxLength * math.sin(math.pi * progress ^ 0.6)
    Whip.theta = math.rad((progress - 0.5) * Whip.SWEEP_DEGREES)

    local count = math.floor(Whip.ext / Whip.HIT_SPACING)
    for k = 1, count do
        if Whip.hits[k] == nil then Whip.hits[k] = { x = 0, y = 0, r = Whip.HIT_RADIUS } end
        local hit = Whip.hits[k]
        hit.x, hit.y = pointAt(k * Whip.HIT_SPACING / Whip.ext)
    end
    Whip.hitCount = count
end

function Whip.update(dt)
    if not Whip.unlocked then return end

    Whip.cooldown = Whip.cooldown - dt
    if Whip.timer > 0 then
        Whip.timer = math.max(0, Whip.timer - dt)
    elseif Whip.cooldown <= 0 then
        startSwing()
    end
    placeHits()
end

-- Punto del latigo en coordenadas de pantalla (a la fraccion f de su largo)
local function screenPointAt(f)
    local x, y = pointAt(f)
    return Camera.toScreen(x, y)
end

-- Dibuja el latigo como una linea con borde blanco (para que se vea sobre cualquier fondo) y una
-- bolita en la punta. Solo se ve mientras dura el golpe. Lo que hace dano son los circulos de
-- Whip.hits, no este dibujo (ver DEBUG_HITBOXES). No crea tablas: se dibuja cada cuadro.
function Whip.draw()
    if Whip.timer <= 0 or Whip.ext < 2 then return end

    for pass = 1, 2 do
        if pass == 1 then
            gfx.setColor(gfx.kColorWhite)
            gfx.setLineWidth(5)
        else
            gfx.setColor(gfx.kColorBlack)
            gfx.setLineWidth(2)
        end
        local prevX, prevY = screenPointAt(0)
        for i = 1, Whip.DRAW_SEGMENTS do
            local x, y = screenPointAt(i / Whip.DRAW_SEGMENTS)
            gfx.drawLine(prevX, prevY, x, y)
            prevX, prevY = x, y
        end
    end
    local tipX, tipY = screenPointAt(1)
    gfx.setColor(gfx.kColorBlack)
    gfx.setLineWidth(1)
    gfx.fillCircleAtPoint(tipX, tipY, 3)
end
