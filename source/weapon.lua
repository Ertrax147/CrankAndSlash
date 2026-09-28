-- Arma cuerpo a cuerpo: gira sola alrededor del personaje.
-- La energia de la manivela solo cambia su velocidad de giro.
local gfx = playdate.graphics

Weapon = {
    ORBIT_RADIUS = 30, -- distancia al personaje
    RADIUS = 6,        -- tamano del arma (para colisiones)
    DAMAGE = 1,
    BASE_SPEED = 120,  -- grados por segundo sin energia
    MAX_SPEED = 540,   -- grados por segundo con energia llena
    HIT_COOLDOWN = 0.4, -- segundos antes de poder golpear de nuevo al mismo enemigo
}

function Weapon.reset()
    Weapon.angle = 0
    Weapon.x = Player.x + Weapon.ORBIT_RADIUS
    Weapon.y = Player.y
end

function Weapon.update(dt)
    local speed = Weapon.BASE_SPEED + (Weapon.MAX_SPEED - Weapon.BASE_SPEED) * Energy.ratio()
    Weapon.angle = (Weapon.angle + speed * dt) % 360
    local rad = math.rad(Weapon.angle)
    Weapon.x = Player.x + Weapon.ORBIT_RADIUS * math.cos(rad)
    Weapon.y = Player.y + Weapon.ORBIT_RADIUS * math.sin(rad)
end

function Weapon.draw()
    gfx.setColor(gfx.kColorBlack)
    gfx.drawLine(Player.x, Player.y, Weapon.x, Weapon.y)
    gfx.fillCircleAtPoint(Weapon.x, Weapon.y, Weapon.RADIUS)
end
