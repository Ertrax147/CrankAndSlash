-- Gemas de experiencia: los enemigos las sueltan al morir. Se gestionan con un Object Pool
-- (mismo patron que enemy.lua y projectile.lua), para no crear basura en memoria.
local gfx = playdate.graphics

Gems = {
    HALF_SIZE = 7, -- radio para recoger la gema al tocarla (el dibujo mide unos 16 px)
    VALUE = 1,     -- experiencia que da cada gema
    POOL_SIZE = 60,
}

-- Dibujo de la gema: un diamante de contorno. (El diamante negro, gem_diamante_negro.png, quedo
-- guardado en source/images por si se quiere usar despues.)
local gemImage = gfx.image.new("images/gem_diamante")

local function newGemObject()
    return { active = false, x = 0, y = 0, value = 0 }
end

Gems.pool = Pool.new(Gems.POOL_SIZE, newGemObject)

-- Devuelve la gema activa mas lejos del jugador (se usa cuando el pool esta lleno)
local function farthestGem()
    local farthest = nil
    local farthestDist2 = -1
    local items = Gems.pool.items
    for i = 1, #items do
        local g = items[i]
        local dx = g.x - Player.x
        local dy = g.y - Player.y
        local dist2 = dx * dx + dy * dy
        if dist2 > farthestDist2 then
            farthest = g
            farthestDist2 = dist2
        end
    end
    return farthest
end

-- Activa una gema en (x, y), el lugar donde murio el enemigo.
-- Si el pool esta lleno, reutiliza la gema mas lejana del jugador (las que quedaron olvidadas atras),
-- para que las gemas nuevas siempre aparezcan.
function Gems.spawn(x, y)
    local g = Gems.pool:acquire() or farthestGem()
    g.x = x
    g.y = y
    g.value = Gems.VALUE
end

function Gems.reset()
    Gems.pool:releaseAll()
end

-- Cada gema que toca al jugador se recoge: da experiencia y desaparece. La mejora "Iman"
-- (Stats.pickupBonus) agranda el area donde se recogen.
function Gems.update()
    local items = Gems.pool.items
    local pickupRadius = Player.RADIUS + Stats.pickupBonus
    for i = 1, #items do
        local g = items[i]
        if g.active and Collision.circles(Player.x, Player.y, pickupRadius, g.x, g.y, Gems.HALF_SIZE) then
            Xp.add(g.value)
            Gems.pool:release(g)
        end
    end
end

-- Dibuja cada gema con su imagen, centrada en su posicion. El dibujo trae un borde blanco
-- para que se distinga del fondo (el pasto tiene muchos puntos negros chiquitos).
function Gems.draw()
    local w, h = gemImage:getSize()
    local items = Gems.pool.items
    for i = 1, #items do
        local g = items[i]
        if g.active then
            local screenX, screenY = Camera.toScreen(g.x, g.y)
            gemImage:draw(screenX - w / 2, screenY - h / 2)
        end
    end
end
