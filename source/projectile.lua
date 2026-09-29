-- Proyectil de la pistola: viaja en linea recta. Se gestiona con un Object Pool
-- (mismo patron que enemy.lua), para no crear basura en memoria.
local gfx = playdate.graphics

Projectile = {
    RADIUS = 3,
    SPEED = 220, -- pixeles por segundo
    DAMAGE = 1,
    POOL_SIZE = 20,
}

local function newProjectileObject()
    return { active = false, x = 0, y = 0, dx = 0, dy = 0 }
end

Projectile.pool = Pool.new(Projectile.POOL_SIZE, newProjectileObject)

-- Activa un proyectil en (x, y) viajando en linea recta hacia (targetX, targetY).
-- Guarda la direccion como un vector normalizado (dx, dy), no el punto de destino,
-- para que el proyectil siga de largo aunque el objetivo se mueva o desaparezca.
function Projectile.spawn(x, y, targetX, targetY)
    local p = Projectile.pool:acquire()
    if not p then return end -- pool lleno: no se dispara

    local dx = targetX - x
    local dy = targetY - y
    local dist = math.sqrt(dx * dx + dy * dy)
    if dist == 0 then dist = 1 end

    p.x = x
    p.y = y
    p.dx = dx / dist
    p.dy = dy / dist
end

function Projectile.reset()
    Projectile.pool:releaseAll()
end

-- Mueve cada proyectil activo en linea recta; se libera solo al salir de la pantalla
function Projectile.update(dt)
    local items = Projectile.pool.items
    for i = 1, #items do
        local p = items[i]
        if p.active then
            p.x = p.x + p.dx * Projectile.SPEED * dt
            p.y = p.y + p.dy * Projectile.SPEED * dt
            if p.x < 0 or p.x > Config.SCREEN_W or p.y < 0 or p.y > Config.SCREEN_H then
                Projectile.pool:release(p)
            end
        end
    end
end

function Projectile.draw()
    gfx.setColor(gfx.kColorBlack)
    local items = Projectile.pool.items
    for i = 1, #items do
        local p = items[i]
        if p.active then
            gfx.fillCircleAtPoint(p.x, p.y, Projectile.RADIUS)
        end
    end
end
