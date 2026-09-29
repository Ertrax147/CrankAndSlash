-- Enemigo basico: persigue al jugador. Se gestiona con un Object Pool.
local gfx = playdate.graphics

Enemy = {
    RADIUS = 7,
    SPEED = 40, -- pixeles por segundo
    HP = 3,
    POOL_SIZE = 40,
}

local function newEnemyObject()
    return { active = false, x = 0, y = 0, hp = 0, hitTimer = 0 }
end

Enemy.pool = Pool.new(Enemy.POOL_SIZE, newEnemyObject)

-- Activa un enemigo del pool en un borde aleatorio de lo que se ve en pantalla,
-- calculado alrededor de la camara (no de un borde fijo, el mundo es infinito).
function Enemy.spawn()
    local e = Enemy.pool:acquire()
    if not e then return end -- pool lleno: no aparece mas por ahora

    local r = Enemy.RADIUS
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
    e.hp = Enemy.HP
    e.hitTimer = 0
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
                e.x = e.x + dx / dist * Enemy.SPEED * dt
                e.y = e.y + dy / dist * Enemy.SPEED * dt
            end
            if e.hitTimer > 0 then e.hitTimer = e.hitTimer - dt end
        end
    end
end

function Enemy.draw()
    gfx.setColor(gfx.kColorBlack)
    local items = Enemy.pool.items
    for i = 1, #items do
        local e = items[i]
        if e.active then
            local screenX, screenY = Camera.toScreen(e.x, e.y)
            gfx.drawCircleAtPoint(screenX, screenY, Enemy.RADIUS)
        end
    end
end
