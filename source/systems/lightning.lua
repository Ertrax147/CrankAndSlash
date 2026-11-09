-- Rayo: cada cierto tiempo cae un rayo en zigzag sobre los enemigos mas cercanos. Mas energia de la
-- manivela = rayos mas seguidos y sobre mas enemigos a la vez. El dano es instantaneo (no hay zona
-- de dano): al caer el rayo, cada enemigo elegido pierde vida. El rayo cae desde el cielo sobre el
-- enemigo; si el personaje tiene antena, esta echa chispas como si lo llamara.
local gfx = playdate.graphics

Lightning = {
    BASE_COOLDOWN = 5.0, -- segundos entre rayos sin energia
    MIN_COOLDOWN = 2.5,  -- segundos entre rayos con energia llena
    RETRY_COOLDOWN = 0.2, -- si no hay enemigos al alcance, vuelve a mirar pronto
    RANGE = 100,         -- distancia maxima a la que elige enemigos (pixeles)
    DAMAGE = 3,          -- vida que le quita a cada enemigo (pocos rayos, pero que se sientan)
    MAX_TARGETS = 1,     -- enemigos a la vez (con 1, la energia solo hace los rayos mas seguidos)
    FLASH_TIME = 0.25,   -- cuanto se ve cada rayo en pantalla
    SEGMENTS = 8,        -- tramos del zigzag
    JITTER = 9,          -- cuanto se desvia cada quiebre hacia los lados (pixeles)
    SLANT = 40,          -- cuanto se corre hacia un lado el punto del cielo de donde cae (pixeles)
    FORK_LENGTH = 24,    -- largo de la rama que sale del rayo
    IMPACT_RADIUS = 14,  -- tamano maximo de la onda donde cae el rayo (estilo SIMPLE)
    TRUNK_SEGMENTS = 8,  -- tramos del tronco en el estilo BRANCHES
    TRUNK_JITTER = 12,   -- cuanto se desvia cada quiebre del tronco (pixeles)
    BRANCH_LENGTH = 16,  -- largo minimo de una rama del tronco (pixeles)
    BRANCH_EXTRA = 24,   -- hasta cuanto mas largo puede ser (al azar)
    SKY_HEIGHT = 100,    -- desde cuanto mas arriba del enemigo nace el tronco (estilo BRANCHES)
}

-- El rayo empieza apagado: el jugador lo consigue como una mejora al subir de nivel (Upgrades),
-- que enciende Lightning.unlocked.
Lightning.startUnlocked = false -- true: la partida empieza con el rayo (la pantalla de pruebas lo puede cambiar)

-- Como se dibuja el rayo (la pantalla de pruebas lo puede cambiar):
--   "BRANCHES": tronco que se estira desde el cielo con muchas ramas, y grietas donde cae
--   "SIMPLE": un zigzag con una sola rama y una onda donde cae
Lightning.style = "BRANCHES"

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

-- Dibuja una linea con borde blanco (para que se vea sobre cualquier fondo)
local function drawOutlined(x0, y0, x1, y1, width, halo)
    gfx.setColor(gfx.kColorWhite)
    gfx.setLineWidth(width + (halo or 3))
    gfx.drawLine(x0, y0, x1, y1)
    gfx.setColor(gfx.kColorBlack)
    gfx.setLineWidth(width)
    gfx.drawLine(x0, y0, x1, y1)
end

-- Estilo SIMPLE: un rayo en zigzag entre dos puntos de pantalla, con una rama a mitad de camino. Cada
-- quiebre se desvia hacia un lado y hacia el otro; "id" y strikeId dan su forma a cada rayo.
local function drawSimpleBolt(x0, y0, x1, y1, id, width)
    local dx, dy = x1 - x0, y1 - y0
    local length = math.sqrt(dx * dx + dy * dy)
    if length < 1 then return end
    local perpX, perpY = -dy / length, dx / length -- direccion perpendicular a la linea
    local prevX, prevY = x0, y0
    local forkAt = math.floor(Lightning.SEGMENTS / 2)
    for i = 1, Lightning.SEGMENTS do
        local f = i / Lightning.SEGMENTS
        local x = x0 + dx * f
        local y = y0 + dy * f
        if i < Lightning.SEGMENTS then -- el ultimo tramo termina justo en el enemigo
            local offset = (noise(id, i, Lightning.strikeId) - 0.5) * 2 * Lightning.JITTER
            x = x + perpX * offset
            y = y + perpY * offset
        end
        drawOutlined(prevX, prevY, x, y, width)
        if i == forkAt then
            -- rama corta que sale del rayo hacia un lado y hacia abajo
            local side = noise(id, 99, Lightning.strikeId) < 0.5 and -1 or 1
            drawOutlined(x, y, x + side * Lightning.FORK_LENGTH * 0.8, y + Lightning.FORK_LENGTH * 0.6, 1)
        end
        prevX, prevY = x, y
    end
end

-- Estilo SIMPLE: el golpe donde cae el rayo: un centro blanco, una onda que se abre y chispas alrededor.
-- progress va de 0 (recien cae) a 1 (se apaga).
local function drawSimpleImpact(x, y, progress)
    local radius = 4 + Lightning.IMPACT_RADIUS * progress
    gfx.setLineWidth(1)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillCircleAtPoint(x, y, 6 - 3 * progress)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawCircleAtPoint(x, y, radius)
    gfx.drawCircleAtPoint(x, y, 3)
    for i = 1, 6 do -- chispas que salen hacia afuera
        local angle = (i / 6) * 2 * math.pi + Lightning.strikeId
        local inner = radius * 0.6
        local outer = radius + 5
        gfx.drawLine(x + math.cos(angle) * inner, y + math.sin(angle) * inner,
            x + math.cos(angle) * outer, y + math.sin(angle) * outer)
    end
end

-- Estilo BRANCHES: una rama que sale de (x, y) hacia el angulo "angle", se quiebra en 2 o 3 tramos y
-- puede tener una subrama. "salt" da a cada rama una forma distinta.
local function drawBranch(x, y, angle, length, depth, id, salt)
    local segments = depth == 1 and 4 or 2
    local step = length / segments
    for j = 1, segments do
        local turned = angle + (noise(id, salt + j, Lightning.strikeId) - 0.5) * 1.3
        local nextX = x + math.cos(turned) * step
        local nextY = y + math.sin(turned) * step
        drawOutlined(x, y, nextX, nextY, 1, 2)
        x, y = nextX, nextY
        if depth == 1 and (j == 2 or j == 3) and noise(id, salt + 50 + j, Lightning.strikeId) < 0.65 then
            local side = noise(id, salt + 60 + j, Lightning.strikeId) < 0.5 and -1 or 1
            drawBranch(x, y, turned + side * 0.8, length * 0.55, 2, id, salt + 100 * j)
        end
    end
end

-- Estilo BRANCHES: el tronco cae desde el cielo hasta el enemigo en zigzag y de cada quiebre salen
-- ramas hacia los lados y hacia abajo. "progress" (0 a 1) maneja la animacion: el tronco se va
-- estirando hacia abajo, las ramas aparecen un momento y al final solo queda un hilo.
local function drawBranchedBolt(x0, y0, x1, y1, id, progress)
    local reveal = math.min(1, (progress + 0.13) / 0.3) -- cuanto del tronco ya cayo
    local width = progress < 0.4 and 3 or (progress < 0.7 and 2 or 1)
    local showBranches = progress > 0.05 and progress < 0.7
    local dx, dy = x1 - x0, y1 - y0
    local length = math.sqrt(dx * dx + dy * dy)
    if length < 1 then return end
    local perpX, perpY = -dy / length, dx / length
    local trunkAngle = math.atan(dy, dx)
    local lastSegment = math.max(1, math.floor(reveal * Lightning.TRUNK_SEGMENTS))
    local prevX, prevY = x0, y0
    for k = 1, lastSegment do
        local f = k / Lightning.TRUNK_SEGMENTS
        local x = x0 + dx * f
        local y = y0 + dy * f
        if k < Lightning.TRUNK_SEGMENTS then -- el ultimo tramo termina justo en el enemigo
            local offset = (noise(id, k, Lightning.strikeId) - 0.5) * 2 * Lightning.TRUNK_JITTER
            x = x + perpX * offset
            y = y + perpY * offset
        end
        drawOutlined(prevX, prevY, x, y, width)
        -- de casi cada quiebre sale una rama, mas corta cerca del suelo
        if showBranches and k >= 2 and k < Lightning.TRUNK_SEGMENTS - 1
            and noise(id, 200 + k, Lightning.strikeId) < 0.85 then
            local side = noise(id, 300 + k, Lightning.strikeId) < 0.5 and -1 or 1
            local angle = trunkAngle + side * (0.35 + noise(id, 400 + k, Lightning.strikeId) * 0.8)
            local branchLength = (Lightning.BRANCH_LENGTH + noise(id, 500 + k, Lightning.strikeId) * Lightning.BRANCH_EXTRA)
                * (1.2 - f * 0.6)
            drawBranch(x, y, angle, branchLength, 1, id, k * 7)
        end
        prevX, prevY = x, y
    end
end

-- Estilo BRANCHES: el disco plano de donde nace el rayo, arriba
local function drawSource(x, y)
    drawOutlined(x - 14, y, x + 14, y, 2)
    drawOutlined(x - 7, y - 3, x + 7, y - 3, 1, 2)
end

-- Estilo BRANCHES: donde cae el rayo, un destello blanco con grietas que se abren hacia los lados
local function drawCracks(x, y, progress)
    local reach = 9 + 15 * progress
    for i = 1, 7 do
        local angle = (i / 7) * 2 * math.pi + noise(i, 3, Lightning.strikeId) * 0.8
        local midX = x + math.cos(angle) * reach * 0.55 + (noise(i, 4, Lightning.strikeId) - 0.5) * 6
        local midY = y + math.sin(angle) * reach * 0.55 + (noise(i, 5, Lightning.strikeId) - 0.5) * 6
        drawOutlined(x, y, midX, midY, 1, 2)
        drawOutlined(midX, midY, x + math.cos(angle) * reach, y + math.sin(angle) * reach, 1, 2)
    end
    gfx.setLineWidth(1)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillCircleAtPoint(x, y, 6 - 3 * progress)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawCircleAtPoint(x, y, 3)
end

-- Chispas cortas alrededor de la bola de la antena: es la antena la que "llama" al rayo
local function drawAntennaSpark(x, y)
    gfx.setLineWidth(1)
    gfx.setColor(gfx.kColorBlack)
    for i = 1, 5 do
        local angle = (i / 5) * math.pi - math.pi + noise(i, 7, Lightning.strikeId) * 0.5
        gfx.drawLine(x + math.cos(angle) * 4, y + math.sin(angle) * 4,
            x + math.cos(angle) * 9, y + math.sin(angle) * 9)
    end
end

-- Dibuja los rayos del ultimo golpe mientras duran (FLASH_TIME): caen desde arriba de la pantalla
-- sobre cada enemigo (segun Lightning.style), y la antena echa chispas.
function Lightning.draw()
    if Lightning.flash <= 0 then return end
    local progress = 1 - Lightning.flash / Lightning.FLASH_TIME -- 0 al caer, 1 al apagarse
    for i = 1, Lightning.targetCount do
        local target = Lightning.targets[i]
        local endX, endY = Camera.toScreen(target.x, target.y)
        -- cae desde un punto del cielo, un poco corrido hacia un lado para que no sea tan vertical
        local startX = endX + (noise(i, 5, Lightning.strikeId) - 0.5) * 2 * Lightning.SLANT
        if Lightning.style == "SIMPLE" then
            local startY = math.min(-10, endY - 60) -- siempre arriba del borde de la pantalla
            drawSimpleBolt(startX, startY, endX, endY, i, progress < 0.5 and 3 or 1)
            drawSimpleImpact(endX, endY, progress)
        else
            local startY = endY - Lightning.SKY_HEIGHT -- nace mas cerca: un rayo mas chico
            if progress < 0.7 then drawSource(startX, startY) end
            drawBranchedBolt(startX, startY, endX, endY, i, progress)
            drawCracks(endX, endY, progress)
        end
    end
    if progress < 0.5 then
        local antennaX, antennaY = Player.antennaWorld()
        if antennaX then
            local screenX, screenY = Camera.toScreen(antennaX, antennaY)
            drawAntennaSpark(screenX, screenY)
        end
    end
end
