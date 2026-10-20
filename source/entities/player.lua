-- Personaje: se mueve con la cruceta
local gfx = playdate.graphics

Player = {
    RADIUS = 8,
    SPEED = 90,        -- pixeles por segundo
    MAX_HP = 5,
    INVULN_TIME = 1.0, -- segundos sin recibir dano despues de un golpe
    FRAME_TIME = 0.15, -- segundos que dura cada cuadro de la caminata
    mechanism = "CRANK", -- que gira en la caja: "CRANK" (manivela) o "WHEEL" (volante), lo cambia la pantalla de pruebas
    boltMode = "BODY", -- de donde salen los rayos: "BODY", "ANTENNA", "BOTH" o "NONE" (lo cambia la pantalla de pruebas)
    -- manivela de la caja (se dibuja por codigo, solo si el personaje la tiene: ver data/characters.lua)
    CRANK_LENGTH = 7,
    WHEEL_RADIUS = 3,
    CRANK_MAX_SPEED = 6,     -- radianes por segundo con la energia llena (mas rapido se ve como temblor a 30 fps)
    -- rayos alrededor del personaje: cuantos y de que largo segun la energia
    BOLT_MIN_ENERGY = 0.1,   -- bajo esto no hay rayos
    BOLT_SEGMENTS = 3,
    BOLT_RADIUS = 12,        -- a que distancia del centro nace cada rayo
    BOLT_STEP = 2.5,         -- largo minimo de cada tramo del zigzag (se le suma hasta 1 px al azar)
    BOLT_COUNT_LOW = 2,      -- rayos con energia media
    BOLT_COUNT_HIGH = 4,     -- rayos con energia alta (mas del 60%)
    BOLT_ANTENNA_RADIUS = 3, -- a que distancia del centro de la bola de la antena nace cada rayo
    BOLT_TICK = 0.1,         -- cada cuantos segundos cambia la forma de los rayos
}

-- Personaje elegido (ver data/characters.lua) y sus 2 cuadros de caminata
-- (miran a la derecha; a la izquierda se voltean)
local frames

-- Carga los dos dibujos del personaje actual. Con el volante se usa la version "_volante" (la caja
-- sin el rayo dibujado, porque el volante se dibuja encima); los personajes sin volante usan siempre
-- el dibujo normal.
local function loadFrames()
    local name = Player.character.SPRITE
    if Player.mechanism == "WHEEL" and Player.character.WHEEL_X then name = name .. "_volante" end
    frames = { gfx.image.new(name .. "_1"), gfx.image.new(name .. "_2") }
end

-- Cambia el personaje con el que se juega
function Player.setCharacter(character)
    Player.character = character
    loadFrames()
end

-- Cambia lo que gira en la caja segun la energia: "CRANK" (manivela) o "WHEEL" (volante)
function Player.setMechanism(mechanism)
    Player.mechanism = mechanism
    loadFrames()
end

Player.setCharacter(Characters[Config.DEBUG_CHARACTER])

function Player.reset()
    Player.x = Config.SCREEN_W / 2
    Player.y = Config.SCREEN_H / 2
    Player.hp = Stats.maxHp()
    Player.invuln = 0
    Player.walkTime = 0       -- cuanto lleva caminando (elige el cuadro del dibujo)
    Player.facingLeft = false -- hacia donde mira
    Player.crankAngle = 0     -- angulo de la manivela de la caja (radianes)
    Player.boltTime = 0       -- reloj para cambiar la forma de los rayos
end

function Player.update(dt)
    local dx, dy = 0, 0
    if playdate.buttonIsPressed(playdate.kButtonLeft) then dx = dx - 1 end
    if playdate.buttonIsPressed(playdate.kButtonRight) then dx = dx + 1 end
    if playdate.buttonIsPressed(playdate.kButtonUp) then dy = dy - 1 end
    if playdate.buttonIsPressed(playdate.kButtonDown) then dy = dy + 1 end

    -- en diagonal no debe ir mas rapido
    if dx ~= 0 and dy ~= 0 then
        dx = dx * 0.7071
        dy = dy * 0.7071
    end

    local speed = Player.SPEED * Stats.speedMult
    Player.x = Player.x + dx * speed * dt
    Player.y = Player.y + dy * speed * dt

    -- el cuadro de caminata solo avanza si se mueve; si esta quieto se muestra el primero
    if dx ~= 0 or dy ~= 0 then
        Player.walkTime = Player.walkTime + dt
    else
        Player.walkTime = 0
    end
    if dx < 0 then Player.facingLeft = true elseif dx > 0 then Player.facingLeft = false end

    -- la manivela gira mas rapido cuanto mas energia hay (sin energia queda quieta)
    Player.crankAngle = Player.crankAngle + Energy.ratio() * Player.CRANK_MAX_SPEED * dt
    Player.boltTime = Player.boltTime + dt

    if Player.invuln > 0 then
        Player.invuln = Player.invuln - dt
        if Player.invuln < 0 then Player.invuln = 0 end
    end
end

function Player.hurt(amount)
    if Player.invuln > 0 then return end
    Player.hp = Player.hp - amount
    Player.invuln = Player.INVULN_TIME
end

-- Numero pseudoaleatorio entre 0 y 1 que depende solo de a, b y c (no toca math.random,
-- asi los rayos no alteran el azar del resto del juego, como la aparicion de enemigos)
local function noise(a, b, c)
    local v = math.sin(a * 12.9898 + b * 78.233 + c * 37.719) * 43758.5453
    return v - math.floor(v)
end

-- Dibuja una linea negra con borde blanco para que se vea sobre cualquier fondo
local function drawOutlinedLine(x1, y1, x2, y2)
    gfx.setColor(gfx.kColorWhite)
    gfx.setLineWidth(3)
    gfx.drawLine(x1, y1, x2, y2)
    gfx.setColor(gfx.kColorBlack)
    gfx.setLineWidth(1)
    gfx.drawLine(x1, y1, x2, y2)
end

-- Dibuja la manivela de la caja: gira con la energia. Va ANTES que el dibujo del personaje,
-- asi cuando apunta hacia adentro de la caja queda tapada por ella.
local function drawCrank(pivotX, pivotY, side)
    local tipX = pivotX + side * Player.CRANK_LENGTH * math.cos(Player.crankAngle)
    local tipY = pivotY + Player.CRANK_LENGTH * math.sin(Player.crankAngle)
    drawOutlinedLine(pivotX, pivotY, tipX, tipY)
    gfx.setColor(gfx.kColorBlack)
    gfx.fillCircleAtPoint(tipX, tipY, 2) -- la perilla
end

-- Dibuja el volante de la caja: un circulo con un rayo que gira con la energia, como la manivela.
-- Va DESPUES del dibujo, encima de la caja (que en la version "_volante" no tiene el rayo dibujado).
local function drawWheel(x, y, side)
    gfx.setColor(gfx.kColorBlack)
    gfx.setLineWidth(1)
    gfx.drawCircleAtPoint(x, y, Player.WHEEL_RADIUS)
    local tipX = x + side * (Player.WHEEL_RADIUS - 1) * math.cos(Player.crankAngle)
    local tipY = y + (Player.WHEEL_RADIUS - 1) * math.sin(Player.crankAngle)
    gfx.drawLine(x, y, tipX, tipY)
    gfx.fillCircleAtPoint(tipX, tipY, 1) -- la perilla
end

-- Dibuja un rayo en zigzag que sale de (startX, startY) hacia el angulo "base". "id" y "tick" solo
-- sirven para que cada rayo tenga su forma y esta cambie cada BOLT_TICK segundos.
local function drawBolt(startX, startY, base, id, tick)
    local x, y = startX, startY
    local side = 1
    for k = 1, Player.BOLT_SEGMENTS do
        -- un quiebre brusco hacia un lado y luego hacia el otro, avanzando hacia afuera
        local turned = base + side * (0.8 + noise(id, k + 1, tick) * 0.4)
        side = -side
        local step = Player.BOLT_STEP + noise(id, k + 10, tick)
        local nextX = x + math.cos(turned) * step + math.cos(base) * 2
        local nextY = y + math.sin(turned) * step + math.sin(base) * 2
        drawOutlinedLine(x, y, nextX, nextY)
        x, y = nextX, nextY
    end
end

-- Dibuja los rayos segun Player.boltMode: "BODY" (alrededor del cuerpo), "ANTENNA" (solo desde la
-- bola de la antena, hacia arriba) o "BOTH". Mas rayos cuanto mas energia. Si el personaje no tiene
-- antena, "ANTENNA" los dibuja alrededor del cuerpo.
local function drawBolts(centerX, centerY, antennaX, antennaY)
    local ratio = Energy.ratio()
    if ratio < Player.BOLT_MIN_ENERGY or Player.boltMode == "NONE" then return end
    local count = Player.BOLT_COUNT_LOW
    if ratio > 0.6 then count = Player.BOLT_COUNT_HIGH end
    local tick = math.floor(Player.boltTime / Player.BOLT_TICK) -- la forma cambia cada BOLT_TICK

    local fromBody = Player.boltMode ~= "ANTENNA" or antennaX == nil
    local fromAntenna = antennaX ~= nil and Player.boltMode ~= "BODY"
    if fromBody and fromAntenna then count = math.max(1, count // 2) end -- con los dos, la mitad en cada uno

    if fromBody then
        for i = 1, count do
            local base = (i / count) * 2 * math.pi + (noise(i, 1, tick) - 0.5) * 0.6
            drawBolt(centerX + math.cos(base) * Player.BOLT_RADIUS, centerY + math.sin(base) * Player.BOLT_RADIUS,
                base, i, tick)
        end
    end
    if fromAntenna then
        for i = 1, count do
            -- repartidos en abanico por encima de la bola (de -180 a 0 grados; el eje y de la pantalla baja)
            local base = -math.pi + ((i - 0.5) / count) * math.pi + (noise(i, 2, tick) - 0.5) * 0.4
            drawBolt(antennaX + math.cos(base) * Player.BOLT_ANTENNA_RADIUS,
                antennaY + math.sin(base) * Player.BOLT_ANTENNA_RADIUS, base, i + 20, tick)
        end
    end
end

-- Dibuja al personaje en el centro de la pantalla: rayos, manivela y cuerpo (alterna cuadros al
-- caminar y se voltea al ir a la izquierda)
function Player.draw()
    -- parpadea mientras es invulnerable
    if Player.invuln > 0 and math.floor(Player.invuln * 10) % 2 == 0 then return end
    local frame = math.floor(Player.walkTime / Player.FRAME_TIME) % 2 + 1
    local image = frames[frame]
    local screenX, screenY = Camera.toScreen(Player.x, Player.y)
    local w, h = image:getSize()
    local side = Player.facingLeft and -1 or 1 -- al mirar a la izquierda todo se refleja
    -- el pivote baja 1 px en el segundo cuadro, igual que el cuerpo
    local antennaX, antennaY
    if Player.character.ANTENNA_X then
        antennaX = screenX + side * (Player.character.ANTENNA_X - w / 2)
        antennaY = screenY + (Player.character.ANTENNA_Y + frame - 1) - h / 2
    end
    local useWheel = Player.mechanism == "WHEEL" and Player.character.WHEEL_X ~= nil
    local pivotX, pivotY
    if Player.character.CRANK_PIVOT_X and not useWheel then
        pivotX = screenX + side * (Player.character.CRANK_PIVOT_X - w / 2)
        pivotY = screenY + (Player.character.CRANK_PIVOT_Y + frame - 1) - h / 2
    end

    if Player.character.BOLTS then drawBolts(screenX, screenY, antennaX, antennaY) end
    if pivotX then drawCrank(pivotX, pivotY, side) end
    local flip = Player.facingLeft and gfx.kImageFlippedX or gfx.kImageUnflipped
    image:draw(screenX - w / 2, screenY - h / 2, flip)
    if useWheel then
        drawWheel(screenX + side * (Player.character.WHEEL_X - w / 2),
            screenY + (Player.character.WHEEL_Y + frame - 1) - h / 2, side)
    end
end
