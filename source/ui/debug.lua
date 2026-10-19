-- Herramientas para revisar el juego mientras se desarrolla (se activan en Config).
local gfx = playdate.graphics

DebugDraw = {}

-- Config.DEBUG_HITBOXES: dibuja los circulos que usa el juego para las colisiones, para comprobar
-- que el dano y los golpes coinciden con lo que se ve en pantalla.
function DebugDraw.hitboxes()
    gfx.setColor(gfx.kColorBlack)
    local playerX, playerY = Camera.toScreen(Player.x, Player.y)
    gfx.drawCircleAtPoint(playerX, playerY, Player.RADIUS)
    local enemies = Enemy.pool.items
    for i = 1, #enemies do
        local e = enemies[i]
        if e.active then
            local x, y = Camera.toScreen(e.x, e.y)
            gfx.drawCircleAtPoint(x, y, e.def.RADIUS)
        end
    end
    for i = 1, #Weapon.list do
        local w = Weapon.list[i]
        for k = 1, #w.hits do
            local hit = w.hits[k]
            local x, y = Camera.toScreen(hit.x, hit.y)
            gfx.drawCircleAtPoint(x, y, hit.r)
        end
    end
    local projectiles = Projectile.pool.items
    for i = 1, #projectiles do
        local p = projectiles[i]
        if p.active then
            local x, y = Camera.toScreen(p.x, p.y)
            gfx.drawCircleAtPoint(x, y, Projectile.RADIUS)
        end
    end
end
