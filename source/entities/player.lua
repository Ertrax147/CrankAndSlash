-- Personaje: se mueve con la cruceta
local gfx = playdate.graphics

Player = {
    RADIUS = 8,
    SPEED = 90,        -- pixeles por segundo
    MAX_HP = 5,
    INVULN_TIME = 1.0, -- segundos sin recibir dano despues de un golpe
    FRAME_TIME = 0.15, -- segundos que dura cada cuadro de la caminata
    -- manivela de la caja (se dibuja por codigo; el pivote esta en el borde exterior de la caja,
    -- que queda a la espalda del personaje)
    CRANK_PIVOT_X = 2,       -- posicion del pivote dentro del dibujo (pixeles desde su esquina)
    CRANK_PIVOT_Y = 19,
    CRANK_LENGTH = 7,
    CRANK_MAX_SPEED = 6,     -- radianes por segundo con la energia llena (mas rapido se ve como temblor a 30 fps)
    -- rayos alrededor del personaje: cuantos y de que largo segun la energia
    BOLT_MIN_ENERGY = 0.1,   -- bajo esto no hay rayos
    BOLT_SEGMENTS = 3,
    BOLT_RADIUS = 12,        -- a que distancia del centro nace cada rayo
    BOLT_STEP = 2.5,         -- largo minimo de cada tramo del zigzag (se le suma hasta 1 px al azar)
    BOLT_COUNT_LOW = 2,      -- rayos con energia media
    BOLT_COUNT_HIGH = 4,     -- rayos con energia alta (mas del 60%)
    BOLT_TICK = 0.1,         -- cada cuantos segundos cambia la forma de los rayos
}

-- Dibujo del personaje: 2 cuadros de caminata (miran a la derecha; a la izquierda se voltean)
local frames = { gfx.image.new("images/player/personaje_1"), gfx.image.new("images/player/personaje_2") }

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

-- Dibuja rayos en zigzag alrededor del personaje: mas rayos cuanto mas energia
local function drawBolts(centerX, centerY)
    local ratio = Energy.ratio()
    if ratio < Player.BOLT_MIN_ENERGY then return end
    local count = Player.BOLT_COUNT_LOW
    if ratio > 0.6 then count = Player.BOLT_COUNT_HIGH end
    local tick = math.floor(Player.boltTime / Player.BOLT_TICK) -- la forma cambia cada BOLT_TICK
    for i = 1, count do
        local base = (i / count) * 2 * math.pi + (noise(i, 1, tick) - 0.5) * 0.6
        local x = centerX + math.cos(base) * Player.BOLT_RADIUS
        local y = centerY + math.sin(base) * Player.BOLT_RADIUS
        local side = 1
        for k = 1, Player.BOLT_SEGMENTS do
            -- un quiebre brusco hacia un lado y luego hacia el otro, avanzando hacia afuera
            local turned = base + side * (0.8 + noise(i, k + 1, tick) * 0.4)
            side = -side
            local step = Player.BOLT_STEP + noise(i, k + 10, tick)
            local nextX = x + math.cos(turned) * step + math.cos(base) * 2
            local nextY = y + math.sin(turned) * step + math.sin(base) * 2
            drawOutlinedLine(x, y, nextX, nextY)
            x, y = nextX, nextY
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
    local pivotX = screenX + side * (Player.CRANK_PIVOT_X - w / 2)
    local pivotY = screenY + (Player.CRANK_PIVOT_Y + frame - 1) - h / 2

    drawBolts(screenX, screenY)
    drawCrank(pivotX, pivotY, side)
    local flip = Player.facingLeft and gfx.kImageFlippedX or gfx.kImageUnflipped
    image:draw(screenX - w / 2, screenY - h / 2, flip)
end
