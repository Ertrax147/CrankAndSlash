-- Armas del jugador: cada una gira sola alrededor del personaje.
-- La energia de la manivela solo cambia su velocidad de giro.
-- Weapon.list guarda todas las armas activas del jugador (hoy solo una, la cuerpo a cuerpo).
local gfx = playdate.graphics

Weapon = {}

-- Dibujo de la cabeza de cada tipo de arma, cargado una sola vez: images["MELEE"], etc.
local images = {}
for typeName, def in pairs(WeaponTypes) do
    images[typeName] = gfx.image.new(def.SPRITE)
end

local CHAIN_SPACING = 4 -- pixeles entre un eslabon de la cadena y el siguiente
local CHAIN_END_GAP = 8 -- la cadena se corta antes de la cabeza, que la tapa

-- Crea una tabla de arma nueva a partir de su tipo (ej: "MELEE"), buscando
-- los valores en WeaponTypes. Cada arma tiene su propia posicion y angulo,
-- para que en el futuro puedan girar varias armas al mismo tiempo.
local function newWeapon(typeName, startAngle)
    local def = WeaponTypes[typeName]
    local angle = startAngle or 0
    return {
        type = typeName,
        def = def,
        angle = angle,
        x = Player.x + def.ORBIT_RADIUS * math.cos(math.rad(angle)),
        y = Player.y + def.ORBIT_RADIUS * math.sin(math.rad(angle)),
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
        local orbit = def.ORBIT_RADIUS * Stats.reachMult -- la mejora "Alcance" aleja el arma
        w.x = Player.x + orbit * math.cos(rad)
        w.y = Player.y + orbit * math.sin(rad)
    end
end

-- Dibuja una cadena de eslabones entre (x0, y0) y (x1, y1), alternando eslabones horizontales
-- y verticales. Es solo visual, no hace dano.
local function drawChain(x0, y0, x1, y1)
    local dx = x1 - x0
    local dy = y1 - y0
    local dist = math.sqrt(dx * dx + dy * dy)
    local count = math.floor((dist - CHAIN_END_GAP) / CHAIN_SPACING)
    for i = 1, count do
        local t = i * CHAIN_SPACING / dist
        local x = x0 + dx * t
        local y = y0 + dy * t
        if i % 2 == 1 then
            gfx.fillRect(x - 2, y - 1, 4, 2)
        else
            gfx.fillRect(x - 1, y - 2, 2, 4)
        end
    end
end

-- Dibuja cada arma: la cadena que la une al personaje (solo visual) y la cabeza del arma en la
-- punta, que es la parte que si hace dano (su zona de colision es el circulo de RADIUS).
function Weapon.draw()
    gfx.setColor(gfx.kColorBlack)
    local playerScreenX, playerScreenY = Camera.toScreen(Player.x, Player.y)
    for i = 1, #Weapon.list do
        local w = Weapon.list[i]
        local screenX, screenY = Camera.toScreen(w.x, w.y)
        drawChain(playerScreenX, playerScreenY, screenX, screenY)
        local image = images[w.type]
        if w.def.ROTATE then
            -- los dibujos miran hacia arriba: se giran (angle + 90) para apuntar hacia afuera de la orbita
            image:drawRotated(screenX, screenY, w.angle + 90)
        else
            local imageW, imageH = image:getSize()
            image:draw(screenX - imageW / 2, screenY - imageH / 2)
        end
    end
end
