-- Enemigos: persiguen al jugador. Cada uno tiene un tipo (EnemyTypes) con su tamano, velocidad,
-- vida y dano. Se gestionan con un Object Pool.
local gfx = playdate.graphics

Enemy = {
    POOL_SIZE = 70, -- mas que antes: en las rondas altas aparecen muchos mas enemigos a la vez
}

local function newEnemyObject()
    return { active = false, x = 0, y = 0, hp = 0, maxHp = 1, hitTimer = 0, animTimer = 0, def = EnemyTypes.LIST[1] }
end

-- Los dos cuadros de animacion de cada tipo, cargados una sola vez: frames[tipo][1] y frames[tipo][2]
local frames = {}
local function loadFrames(t)
    frames[t] = { gfx.image.new(t.SPRITE .. "_1"), gfx.image.new(t.SPRITE .. "_2") }
end
for i = 1, #EnemyTypes.LIST do
    loadFrames(EnemyTypes.LIST[i])
end
loadFrames(EnemyTypes.BOSS) -- el jefe no esta en LIST, pero tambien tiene sus dibujos

Enemy.pool = Pool.new(Enemy.POOL_SIZE, newEnemyObject)

-- Elige un tipo de enemigo al azar entre los que ya pueden aparecer en esta ronda (MIN_ROUND),
-- con mas probabilidad para los de mayor WEIGHT.
local function pickType()
    local total = 0
    for i = 1, #EnemyTypes.LIST do
        local t = EnemyTypes.LIST[i]
        if Round.number >= t.MIN_ROUND then total = total + t.WEIGHT end
    end
    local roll = math.random(total)
    local accumulated = 0
    for i = 1, #EnemyTypes.LIST do
        local t = EnemyTypes.LIST[i]
        if Round.number >= t.MIN_ROUND then
            accumulated = accumulated + t.WEIGHT
            if roll <= accumulated then return t end
        end
    end
end

-- Activa un enemigo del tipo "def" en un borde aleatorio de lo que se ve en pantalla,
-- calculado alrededor de la camara (no de un borde fijo, el mundo es infinito).
local function spawnOfType(def)
    local e = Enemy.pool:acquire()
    if not e then return end -- pool lleno: no aparece mas por ahora

    local r = def.RADIUS
    -- math.random(m, n) necesita enteros; Camera.x/y son decimales, por eso el floor
    local left = math.floor(Camera.x - Config.SCREEN_W / 2)
    local right = math.floor(Camera.x + Config.SCREEN_W / 2)
    local top = math.floor(Camera.y - Config.SCREEN_H / 2)
    local bottom = math.floor(Camera.y + Config.SCREEN_H / 2)

    local side = math.random(4)
    if side == 1 then
        e.x = math.random(left, right); e.y = top - r
    elseif side == 2 then
        e.x = math.random(left, right); e.y = bottom + r
    elseif side == 3 then
        e.x = left - r; e.y = math.random(top, bottom)
    else
        e.x = right + r; e.y = math.random(top, bottom)
    end
    e.def = def
    e.hp = def.HP * Difficulty.hpMult() -- mas vida en las rondas altas
    e.maxHp = e.hp -- para dibujar la barra de vida del jefe
    e.hitTimer = 0
    e.animTimer = math.random() * def.ANIM_TIME * 2 -- empieza en un punto al azar, asi no aletean todos igual
end

-- Hace aparecer un enemigo normal, de un tipo elegido segun la ronda
function Enemy.spawn()
    spawnOfType(pickType())
end

-- Hace aparecer al jefe (se llama al empezar una ronda de jefe)
function Enemy.spawnBoss()
    spawnOfType(EnemyTypes.BOSS)
end

function Enemy.reset()
    Enemy.pool:releaseAll()
end

-- Devuelve el enemigo activo mas cercano al punto (x, y), o nil si no hay ninguno.
-- Compara distancias al cuadrado para evitar raices cuadradas innecesarias.
function Enemy.closest(x, y)
    local items = Enemy.pool.items
    local best = nil
    local bestDist = nil
    for i = 1, #items do
        local e = items[i]
        if e.active then
            local dx = e.x - x
            local dy = e.y - y
            local dist = dx * dx + dy * dy
            if not bestDist or dist < bestDist then
                bestDist = dist
                best = e
            end
        end
    end
    return best
end

function Enemy.update(dt)
    local items = Enemy.pool.items
    for i = 1, #items do
        local e = items[i]
        if e.active then
            local dx = Player.x - e.x
            local dy = Player.y - e.y
            local dist = math.sqrt(dx * dx + dy * dy)
            if dist > 0 then
                local dirX = dx / dist
                local dirY = dy / dist
                if e.def.WOBBLE then
                    -- zigzag: se suma un empuje hacia un lado (perpendicular a la direccion al jugador)
                    -- que cambia de lado con el tiempo; animTimer parte distinto en cada enemigo
                    local sway = math.sin(e.animTimer * e.def.WOBBLE_SPEED) * e.def.WOBBLE
                    dirX, dirY = dirX - dirY * sway, dirY + dirX * sway
                end
                e.x = e.x + dirX * e.def.SPEED * dt
                e.y = e.y + dirY * e.def.SPEED * dt
            end
            if e.hitTimer > 0 then e.hitTimer = e.hitTimer - dt end
            e.animTimer = e.animTimer + dt
        end
    end
end

-- Dibuja cada enemigo con su dibujo, centrado en su posicion. Alterna entre los dos cuadros de
-- su tipo cada ANIM_TIME segundos (por eso los fantasmas "flotan" y los murcielagos aletean).
-- Los dibujos traen un borde blanco para distinguirse del fondo. La colision sigue siendo un
-- circulo de tamano RADIUS, aunque el dibujo sea mas grande o de otra forma.
local function drawEnemy(e)
    local screenX, screenY = Camera.toScreen(e.x, e.y)
    local frameNumber = math.floor(e.animTimer / e.def.ANIM_TIME) % 2 + 1
    local image = frames[e.def][frameNumber]
    local w, h = image:getSize()
    image:draw(screenX - w / 2, screenY - h / 2)
    if e.def.BOSS then
        -- barra de vida del jefe, encima de su dibujo: se vacia a medida que le pegas
        local barW, barH = 40, 5
        local barX = screenX - barW / 2
        local barY = screenY - h / 2 - barH - 3
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRect(barX - 1, barY - 1, barW + 2, barH + 2)
        gfx.setColor(gfx.kColorBlack)
        gfx.drawRect(barX, barY, barW, barH)
        gfx.fillRect(barX, barY, barW * math.max(0, e.hp) / e.maxHp, barH)
    end
end

-- El jefe se dibuja en una segunda pasada, para que quede siempre encima de los demas enemigos
-- (si no, segun su lugar en el pool, otros enemigos lo taparian y se perderia entre ellos).
function Enemy.draw()
    local items = Enemy.pool.items
    for i = 1, #items do
        local e = items[i]
        if e.active and not e.def.BOSS then drawEnemy(e) end
    end
    for i = 1, #items do
        local e = items[i]
        if e.active and e.def.BOSS then drawEnemy(e) end
    end
end
