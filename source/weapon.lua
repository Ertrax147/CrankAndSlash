-- Armas del jugador: cada una gira sola alrededor del personaje.
-- La energia de la manivela solo cambia su velocidad de giro.
-- Weapon.list guarda todas las armas activas del jugador (hoy solo una, la cuerpo a cuerpo).
local gfx = playdate.graphics

Weapon = {}

-- Crea una tabla de arma nueva a partir de su tipo (ej: "MELEE"), buscando
-- los valores en WeaponTypes. Cada arma tiene su propia posicion y angulo,
-- para que en el futuro puedan girar varias armas al mismo tiempo.
local function newWeapon(typeName)
    local def = WeaponTypes[typeName]
    return {
        type = typeName,
        def = def,
        angle = 0,
        x = Player.x + def.ORBIT_RADIUS,
        y = Player.y,
    }
end

-- Reinicia la lista de armas del jugador a su estado inicial
function Weapon.reset()
    Weapon.list = { newWeapon("MELEE") }
end

-- Actualiza la posicion de cada arma: gira alrededor del personaje,
-- mas rapido mientras mas energia de la manivela hay (Energy.ratio va de 0 a 1)
function Weapon.update(dt)
    for i = 1, #Weapon.list do
        local w = Weapon.list[i]
        local def = w.def
        local speed = def.BASE_SPEED + (def.MAX_SPEED - def.BASE_SPEED) * Energy.ratio()
        w.angle = (w.angle + speed * dt) % 360
        local rad = math.rad(w.angle)
        w.x = Player.x + def.ORBIT_RADIUS * math.cos(rad)
        w.y = Player.y + def.ORBIT_RADIUS * math.sin(rad)
    end
end

-- Dibuja cada arma: una linea que la une al personaje (solo visual, no hace dano)
-- y un circulo relleno en la punta (esa es la parte que si hace dano)
function Weapon.draw()
    gfx.setColor(gfx.kColorBlack)
    local playerScreenX, playerScreenY = Camera.toScreen(Player.x, Player.y)
    for i = 1, #Weapon.list do
        local w = Weapon.list[i]
        local screenX, screenY = Camera.toScreen(w.x, w.y)
        gfx.drawLine(playerScreenX, playerScreenY, screenX, screenY)
        gfx.fillCircleAtPoint(screenX, screenY, w.def.RADIUS)
    end
end
