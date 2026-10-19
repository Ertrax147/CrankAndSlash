-- Gemas de experiencia: los enemigos las sueltan al morir. Se gestionan con un Object Pool
-- (mismo patron que enemy.lua y projectile.lua), para no crear basura en memoria.
local gfx = playdate.graphics

Gems = {
    HALF_SIZE = 6, -- la gema es un rombo de 12 px de alto
    HALO = 2,      -- borde blanco alrededor, para que no se pierda entre los puntos del pasto
    VALUE = 1,     -- experiencia que da cada gema
    POOL_SIZE = 60,
}

local function newGemObject()
    return { active = false, x = 0, y = 0, value = 0 }
end

Gems.pool = Pool.new(Gems.POOL_SIZE, newGemObject)

-- Activa una gema en (x, y), el lugar donde murio el enemigo
function Gems.spawn(x, y)
    local g = Gems.pool:acquire()
    if not g then return end -- pool lleno: esta gema no aparece
    g.x = x
    g.y = y
    g.value = Gems.VALUE
end

function Gems.reset()
    Gems.pool:releaseAll()
end

-- Cada gema que toca al jugador se recoge: da experiencia y desaparece.
function Gems.update()
    local items = Gems.pool.items
    for i = 1, #items do
        local g = items[i]
        if g.active and Collision.circles(Player.x, Player.y, Player.RADIUS, g.x, g.y, Gems.HALF_SIZE) then
            Xp.add(g.value)
            Gems.pool:release(g)
        end
    end
end

-- Dibuja un rombo de "radio" s centrado en (x, y)
local function fillDiamond(x, y, s)
    gfx.fillPolygon(x, y - s, x + s, y, x, y + s, x - s, y)
end

-- Dibuja cada gema como un rombo negro con un punto blanco al centro y un halo blanco por fuera,
-- para que se distinga del fondo (el pasto tiene muchos puntos negros chiquitos).
function Gems.draw()
    local s = Gems.HALF_SIZE
    local items = Gems.pool.items
    for i = 1, #items do
        local g = items[i]
        if g.active then
            local screenX, screenY = Camera.toScreen(g.x, g.y)
            gfx.setColor(gfx.kColorWhite)
            fillDiamond(screenX, screenY, s + Gems.HALO)
            gfx.setColor(gfx.kColorBlack)
            fillDiamond(screenX, screenY, s)
            gfx.setColor(gfx.kColorWhite)
            gfx.fillRect(screenX - 1, screenY - 2, 2, 4)
        end
    end
end
