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
    DAMAGE = 2,           -- vida que le quita a un enemigo por golpe (la espada quita 1)
    HIT_RADIUS = 6,       -- radio de cada circulo de dano
    HIT_SPACING = 10,     -- distancia entre un circulo de dano y el siguiente
    DRAW_SEGMENTS = 6,    -- en cuantos tramos se dibuja la curva del latigo (estilo LINE)
    ARC_STEPS = 28,       -- circulos con los que se dibuja la banda del estilo ARC (muchos, para que el borde salga liso)
    ARC_THICKNESS = 4.5,  -- radio de la banda en el mango; se afina hasta la punta
    -- estilo BRAID (el latigo trenzado de verdad)
    HANDLE_LENGTH = 13,   -- largo del mango rigido, en pixeles
    HANDLE_RADIUS = 3.3,  -- grosor del mango
    ROPE_RADIUS = 2.3,    -- grosor de la cuerda justo despues del mango; se afina hasta la punta
    WAVE_AMPLITUDE = 17,  -- cuanto sube la lazada que recorre el latigo al golpear (pixeles)
    WAVE_WIDTH = 0.22,    -- que tan ancha es esa lazada (fraccion del largo del latigo)
    WAVE_TRAVEL = 0.4,    -- en que parte del golpe la lazada llega a la punta (0 a 1)
    FRINGE_LENGTH = 7,    -- largo del fleco de la punta
}

-- El latigo empieza apagado: el jugador lo consigue como una mejora al subir de nivel (Upgrades),
-- que enciende Whip.unlocked.
Whip.startUnlocked = false -- true: la partida empieza con el latigo (la pantalla de pruebas lo puede cambiar)

-- Hacia que lado pega cada golpe (la pantalla de pruebas lo puede cambiar):
--   "NEAREST": hacia el lado donde esta el enemigo mas cercano (los enemigos te persiguen, asi que
--              casi siempre estan detras de ti)
--   "ALTERNATE": un golpe a un lado y el siguiente al otro
--   "FACING": hacia donde mira el jugador (como el latigo de Vampire Survivors)
Whip.aimMode = "NEAREST"

-- Como se dibuja el latigo (la pantalla de pruebas lo puede cambiar):
--   "BRAID": un latigo de cuero: mango, cuerda trenzada que se afina, una lazada que recorre el latigo
--            al golpear (el chasquido) y flecos en la punta
--   "ARC": una banda negra gruesa en el mango que se afina hasta la punta
--   "LINE": una linea fina con una bolita en la punta (el primer diseno)
Whip.drawStyle = "BRAID"

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
-- Estilo BRAID: cuanto sube el latigo a la fraccion f por la lazada, una onda que viaja del mango
-- a la punta durante el golpe y deja el latigo recto al llegar (como el chasquido de un latigo).
local function waveOffset(f)
    local progress = 1 - Whip.timer / Whip.SWING_TIME
    local center = math.min(1, progress / Whip.WAVE_TRAVEL) * 1.3 - 0.15 -- va de antes del mango a mas alla de la punta
    local distance = (f - center) / Whip.WAVE_WIDTH
    return Whip.WAVE_AMPLITUDE * math.exp(-distance * distance)
end

local function pointAt(f)
    local x = Player.x + Whip.side * math.cos(Whip.theta) * Whip.ext * f
    local y = Player.y + math.sin(Whip.theta) * Whip.ext * f - Whip.BEND * math.sin(math.pi * f)
    if Whip.drawStyle == "BRAID" then y = y - waveOffset(f) end
    return x, y
end

-- Elige el lado del proximo golpe (1 = derecha, -1 = izquierda) segun Whip.aimMode
local function chooseSide()
    if Whip.aimMode == "ALTERNATE" and Whip.swingId > 0 then
        return -Whip.side -- el primer golpe va hacia donde mira; los demas se alternan
    end
    if Whip.aimMode == "NEAREST" then
        local target = Enemy.closest(Player.x, Player.y)
        if target and target.x ~= Player.x then
            return target.x > Player.x and 1 or -1
        end
    end
    return Player.facingLeft and -1 or 1 -- "FACING", o no hay enemigos a quienes apuntar
end

-- Empieza un golpe nuevo
local function startSwing()
    Whip.side = chooseSide() -- antes de sumar el golpe: chooseSide mira si ya hubo uno
    Whip.swingId = Whip.swingId + 1
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

-- Estilo LINE: el latigo como una linea con borde blanco (para que se vea sobre cualquier fondo) y una
-- bolita en la punta. Solo se ve mientras dura el golpe. Lo que hace dano son los circulos de
-- Whip.hits, no este dibujo (ver DEBUG_HITBOXES). No crea tablas: se dibuja cada cuadro.
local function drawLineStyle()

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

-- Estilo ARC: el latigo como una banda negra gruesa en el mango que se va afinando hasta la punta, con
-- un borde blanco para que se vea sobre cualquier fondo. Se hace con circulos a lo largo de la curva:
-- primero los blancos (un poco mas grandes) y encima los negros. Es mas delgada mientras el latigo
-- aun no se estira del todo.
local function drawArcStyle()
    local stretch = math.min(1, Whip.ext / (Whip.LENGTH * Stats.reachMult) * 1.5)
    for pass = 1, 2 do
        if pass == 1 then
            gfx.setColor(gfx.kColorWhite)
        else
            gfx.setColor(gfx.kColorBlack)
        end
        for i = 1, Whip.ARC_STEPS do
            local f = i / Whip.ARC_STEPS
            local x, y = screenPointAt(f)
            local radius = Whip.ARC_THICKNESS * (1 - f) * stretch + 0.8
            if pass == 1 then radius = radius + 1.5 end
            gfx.fillCircleAtPoint(x, y, radius)
        end
    end
end

-- Estilo BRAID: el latigo de cuero. Un mango negro con un pomo, y despues la cuerda: una banda negra
-- con borde blanco que se afina hasta la punta, con rayitas blancas cruzadas que imitan la trenza, y
-- unos flecos al final. Todo se hace con circulos y lineas sobre la curva (la misma de la zona de dano).
local function drawBraidStyle()
    local stretch = math.min(1, Whip.ext / (Whip.LENGTH * Stats.reachMult) * 1.5)
    local handleEnd = math.min(0.4, Whip.HANDLE_LENGTH / Whip.ext) -- fraccion del largo que ocupa el mango

    -- 1) el cuerpo del latigo: primero todo el borde blanco, luego todo el negro
    for pass = 1, 2 do
        if pass == 1 then gfx.setColor(gfx.kColorWhite) else gfx.setColor(gfx.kColorBlack) end
        for i = 0, Whip.ARC_STEPS do
            local f = i / Whip.ARC_STEPS
            local x, y = screenPointAt(f)
            local radius
            if f <= handleEnd then
                radius = Whip.HANDLE_RADIUS -- el mango es parejo
            else
                -- la cuerda: gruesa al salir del mango y fina en la punta
                local along = (f - handleEnd) / (1 - handleEnd)
                radius = (Whip.ROPE_RADIUS * (1 - 0.65 * along)) * stretch + 0.6
            end
            if pass == 1 then radius = radius + 1.4 end
            gfx.fillCircleAtPoint(x, y, radius)
        end
    end

    -- 2) la trenza: rayitas blancas cruzadas, inclinadas a un lado y al otro, solo donde la cuerda es gruesa
    gfx.setColor(gfx.kColorWhite)
    gfx.setLineWidth(1)
    for i = 1, Whip.ARC_STEPS - 1 do
        local f = i / Whip.ARC_STEPS
        if f > handleEnd and i % 2 == 0 then
            local along = (f - handleEnd) / (1 - handleEnd)
            local radius = (Whip.ROPE_RADIUS * (1 - 0.65 * along)) * stretch + 0.6
            if radius >= 1.5 then
                local x, y = screenPointAt(f)
                local nextX, nextY = screenPointAt(f + 1 / Whip.ARC_STEPS)
                local dirX, dirY = nextX - x, nextY - y
                local length = math.sqrt(dirX * dirX + dirY * dirY)
                if length > 0 then
                    dirX, dirY = dirX / length, dirY / length
                    local lean = (i % 4 == 0) and 1.0 or -1.0 -- se alterna la inclinacion
                    local across = radius * 0.75
                    gfx.drawLine(x - dirY * across + dirX * lean, y + dirX * across + dirY * lean,
                        x + dirY * across - dirX * lean, y - dirX * across - dirY * lean)
                end
            end
        end
    end

    -- 3) el pomo del mango (la bolita del extremo) y el anillo que lo une a la cuerda
    local baseX, baseY = screenPointAt(0)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillCircleAtPoint(baseX, baseY, 5.4)
    gfx.setColor(gfx.kColorBlack)
    gfx.fillCircleAtPoint(baseX, baseY, 4.2)
    local ringX, ringY = screenPointAt(handleEnd)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillCircleAtPoint(ringX, ringY, 1.2)

    -- 4) los flecos de la punta: tres tiras cortas que se abren
    local tipX, tipY = screenPointAt(1)
    local prevX, prevY = screenPointAt(0.93)
    local dirX, dirY = tipX - prevX, tipY - prevY
    local length = math.sqrt(dirX * dirX + dirY * dirY)
    if length > 0 then
        local baseAngle = math.atan(dirY, dirX)
        for k = -1, 1 do
            local angle = baseAngle + k * 0.55
            local reach = Whip.FRINGE_LENGTH - math.abs(k) * 1.5
            local endX, endY = tipX + math.cos(angle) * reach, tipY + math.sin(angle) * reach
            gfx.setColor(gfx.kColorWhite)
            gfx.setLineWidth(3)
            gfx.drawLine(tipX, tipY, endX, endY)
            gfx.setColor(gfx.kColorBlack)
            gfx.setLineWidth(1)
            gfx.drawLine(tipX, tipY, endX, endY)
        end
    end
end

-- Dibuja el latigo segun Whip.drawStyle. Solo se ve mientras dura el golpe. Lo que hace dano son los
-- circulos de Whip.hits, no este dibujo (ver DEBUG_HITBOXES).
function Whip.draw()
    if Whip.timer <= 0 or Whip.ext < 2 then return end
    if Whip.drawStyle == "LINE" then
        drawLineStyle()
    elseif Whip.drawStyle == "ARC" then
        drawArcStyle()
    else
        drawBraidStyle()
    end
end
