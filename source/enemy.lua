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

-- Activa un enemigo del pool en un borde aleatorio de la pantalla
function Enemy.spawn()
    local e = Enemy.pool:acquire()
    if not e then return end -- pool lleno: no aparece mas por ahora

    local r = Enemy.RADIUS
    local side = math.random(4)
    if side == 1 then
        e.x = math.random(0, Config.SCREEN_W); e.y = -r
    elseif side == 2 then
        e.x = math.random(0, Config.SCREEN_W); e.y = Config.SCREEN_H + r
    elseif side == 3 then
        e.x = -r; e.y = math.random(0, Config.SCREEN_H)
    else
        e.x = Config.SCREEN_W + r; e.y = math.random(0, Config.SCREEN_H)
    end
    e.hp = Enemy.HP
    e.hitTimer = 0
end

function Enemy.reset()
    Enemy.pool:releaseAll()
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
            gfx.drawCircleAtPoint(e.x, e.y, Enemy.RADIUS)
        end
    end
end
