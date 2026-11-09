-- Rayo: cada cierto tiempo cae un rayo en zigzag sobre los enemigos mas cercanos. Mas energia de la
-- manivela = rayos mas seguidos y sobre mas enemigos a la vez. El dano es instantaneo (no hay zona
-- de dano): al caer el rayo, cada enemigo elegido pierde vida. El rayo sale de la antena del
-- personaje, o de su centro si no tiene.
local gfx = playdate.graphics

Lightning = {
    BASE_COOLDOWN = 2.0, -- segundos entre rayos sin energia
    MIN_COOLDOWN = 0.7,  -- segundos entre rayos con energia llena
    RETRY_COOLDOWN = 0.2, -- si no hay enemigos al alcance, vuelve a mirar pronto
    RANGE = 110,         -- distancia maxima a la que elige enemigos (pixeles)
    DAMAGE = 3,          -- vida que le quita a cada enemigo
    MAX_TARGETS = 3,     -- enemigos a la vez con la energia llena (sin energia, 1)
    FLASH_TIME = 0.15,   -- cuanto se ve cada rayo en pantalla
    SEGMENTS = 6,        -- tramos del zigzag
    JITTER = 7,          -- cuanto se desvia cada quiebre hacia los lados (pixeles)
}

-- El rayo empieza apagado: el jugador lo consigue como una mejora al subir de nivel (Upgrades),
-- que enciende Lightning.unlocked.
Lightning.startUnlocked = false -- true: la partida empieza con el rayo (la pantalla de pruebas lo puede cambiar)

function Lightning.reset()
    Lightning.unlocked = Lightning.startUnlocked
    Lightning.cooldown = 0
    Lightning.flash = 0      -- tiempo que le queda al rayo en pantalla (0 = no se ve)
    Lightning.strikeId = 0   -- numero del ultimo rayo; da forma distinta al zigzag de cada uno
    Lightning.targets = Lightning.targets or {} -- donde cayo cada rayo {x, y}; se reutilizan
    Lightning.targetCount = 0
end

-- Numero entre 0 y 1 que depende solo de a, b y c (igual que en player.lua: no se usa math.random
-- para no alterar el azar del resto del juego, como la aparicion de enemigos).
local function noise(a, b, c)
    local v = math.sin(a * 12.9898 + b * 78.233 + c * 37.719) * 43758.5453
    return v - math.floor(v)
end

-- Cuantos enemigos golpea el rayo segun la energia: 1 sin energia, MAX_TARGETS con la energia llena
local function targetsForEnergy()
    local count = 1 + math.floor(Energy.ratio() * (Lightning.MAX_TARGETS - 1) + 0.5)
    return math.min(count, Lightning.MAX_TARGETS)
end

-- true si el enemigo e ya esta en la lista picked (los primeros "count" elementos)
local function alreadyPicked(picked, count, e)
    for i = 1, count do
        if picked[i] == e then return true end
    end
    return false
end

-- Busca el enemigo mas cercano al jugador, dentro del alcance, que no este ya elegido
local function nearestUnpicked(picked, count)
    local items = Enemy.pool.items
    local best = nil
    local bestDist = Lightning.RANGE * Lightning.RANGE
    for i = 1, #items do
        local e = items[i]
        if e.active and not alreadyPicked(picked, count, e) then
            local dx = e.x - Player.x
            local dy = e.y - Player.y
            local dist = dx * dx + dy * dy
            if dist <= bestDist then
                bestDist = dist
                best = e
            end
        end
    end
    return best
end

local picked = {} -- enemigos elegidos en el rayo actual (se reutiliza para no crear tablas)

-- Hace caer un rayo: elige a los enemigos mas cercanos, les quita vida y guarda donde cayo
local function strike()
    local wanted = targetsForEnergy()
    local count = 0
    for i = 1, wanted do
        local e = nearestUnpicked(picked, count)
        if not e then break end
        count = count + 1
        picked[count] = e
    end
    if count == 0 then
        Lightning.cooldown = Lightning.RETRY_COOLDOWN -- nadie al alcance: no gasta el rayo
        return
    end

    Lightning.strikeId = Lightning.strikeId + 1
    Lightning.flash = Lightning.FLASH_TIME
    Lightning.targetCount = count
    for i = 1, count do
        local e = picked[i]
        if Lightning.targets[i] == nil then Lightning.targets[i] = { x = 0, y = 0 } end
        Lightning.targets[i].x = e.x
        Lightning.targets[i].y = e.y
        -- el dano es la ultima accion: si el enemigo muere, vuelve al pool y sus datos se reusan
        Combat.hurtEnemy(e, Lightning.DAMAGE * Stats.damageMult)
    end
    for i = 1, count do picked[i] = nil end -- no dejar enemigos guardados de un rayo a otro
    -- igual que Ranged.update: mas energia, menos espera entre rayos
    Lightning.cooldown = Lightning.BASE_COOLDOWN - (Lightning.BASE_COOLDOWN - Lightning.MIN_COOLDOWN) * Energy.ratio()
end

function Lightning.update(dt)
    if not Lightning.unlocked then return end
    if Lightning.flash > 0 then Lightning.flash = math.max(0, Lightning.flash - dt) end
    Lightning.cooldown = Lightning.cooldown - dt
    if Lightning.cooldown <= 0 then strike() end
end

-- Dibuja un zigzag con borde blanco entre dos puntos de pantalla. Cada quiebre se desvia hacia un
-- lado y hacia el otro; "id" da su forma a cada rayo y a cada tramo.
local function drawZigzag(x0, y0, x1, y1, id)
    local dx, dy = x1 - x0, y1 - y0
    local length = math.sqrt(dx * dx + dy * dy)
    if length < 1 then return end
    local perpX, perpY = -dy / length, dx / length -- direccion perpendicular a la linea
    for pass = 1, 2 do
        if pass == 1 then
            gfx.setColor(gfx.kColorWhite)
            gfx.setLineWidth(5)
        else
            gfx.setColor(gfx.kColorBlack)
            gfx.setLineWidth(2)
        end
        local prevX, prevY = x0, y0
        for i = 1, Lightning.SEGMENTS do
            local f = i / Lightning.SEGMENTS
            local x = x0 + dx * f
            local y = y0 + dy * f
            if i < Lightning.SEGMENTS then -- el ultimo tramo termina justo en el enemigo
                local offset = (noise(id, i, Lightning.strikeId) - 0.5) * 2 * Lightning.JITTER
                x = x + perpX * offset
                y = y + perpY * offset
            end
            gfx.drawLine(prevX, prevY, x, y)
            prevX, prevY = x, y
        end
    end
end

-- Dibuja los rayos del ultimo golpe mientras duran (FLASH_TIME): del personaje a cada enemigo,
-- con un circulo donde cae.
function Lightning.draw()
    if Lightning.flash <= 0 then return end
    local originX, originY = Player.antennaWorld()
    if not originX then originX, originY = Player.x, Player.y end
    local startX, startY = Camera.toScreen(originX, originY)
    for i = 1, Lightning.targetCount do
        local target = Lightning.targets[i]
        local endX, endY = Camera.toScreen(target.x, target.y)
        drawZigzag(startX, startY, endX, endY, i)
        gfx.setColor(gfx.kColorBlack)
        gfx.setLineWidth(1)
        gfx.fillCircleAtPoint(endX, endY, 4)
    end
end
