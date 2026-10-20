-- Armas del jugador: cada una gira sola alrededor del personaje.
-- La energia de la manivela solo cambia su velocidad de giro.
-- Weapon.list guarda todas las armas activas del jugador (hoy solo una, la espada larga).
-- Cada arma tiene su zona de dano en w.hits: una lista de circulos {x, y, r} que se mueven con ella.
local gfx = playdate.graphics

Weapon = {}

-- Dibujo de cada tipo de arma, cargado una sola vez: images["ESPADA_LARGA"], etc.
local images = {}
for typeName, def in pairs(WeaponTypes) do
    images[typeName] = gfx.image.new(def.SPRITE)
end

local CHAIN_SPACING = 4 -- pixeles entre un eslabon de la cadena y el siguiente
local CHAIN_END_GAP = 8 -- la cadena se corta antes de la cabeza, que la tapa

-- Pone el arma segun su angulo: calcula el centro del dibujo (w.x, w.y) y la posicion de cada
-- circulo de su zona de dano. Los circulos estan sobre la linea que sale del jugador hacia el arma.
local function place(w)
    local def = w.def
    local rad = math.rad(w.angle)
    local cosA = math.cos(rad)
    local sinA = math.sin(rad)
    local orbit = def.ORBIT_RADIUS * Stats.reachMult -- la mejora "Alcance" aleja el arma
    w.x = Player.x + orbit * cosA
    w.y = Player.y + orbit * sinA
    for k = 1, #def.HITBOXES do
        local hitbox = def.HITBOXES[k]
        local hit = w.hits[k]
        hit.x = w.x + hitbox.offset * cosA
        hit.y = w.y + hitbox.offset * sinA
    end
end

-- Crea una tabla de arma nueva a partir de su tipo (ej: "ESPADA_LARGA"), buscando
-- los valores en WeaponTypes. Cada arma tiene su propia posicion y angulo,
-- para que en el futuro puedan girar varias armas al mismo tiempo.
local function newWeapon(typeName, startAngle)
    local def = WeaponTypes[typeName]
    local w = { type = typeName, def = def, angle = startAngle or 0, x = 0, y = 0, hits = {} }
    for k = 1, #def.HITBOXES do
        w.hits[k] = { x = 0, y = 0, r = def.HITBOXES[k].radius }
    end
    place(w)
    return w
end

Weapon.startingType = "ESPADA_LARGA" -- arma con la que empieza cada partida (la pantalla de pruebas la puede cambiar)

-- Reinicia la lista de armas del jugador a su estado inicial
function Weapon.reset()
    Weapon.list = { newWeapon(Weapon.startingType) }
end

-- Actualiza la posicion de cada arma: gira alrededor del personaje,
-- mas rapido mientras mas energia de la manivela hay (Energy.ratio va de 0 a 1)
function Weapon.update(dt)
    for i = 1, #Weapon.list do
        local w = Weapon.list[i]
        local def = w.def
        local speed = def.BASE_SPEED + (def.MAX_SPEED - def.BASE_SPEED) * Energy.ratio()
        w.angle = (w.angle + speed * dt) % 360
        place(w)
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

-- Dibuja cada arma: su cadena (si tiene, es solo visual) y su dibujo en el centro del arma.
-- Lo que hace dano son los circulos de w.hits, no el dibujo (ver DEBUG_HITBOXES).
function Weapon.draw()
    gfx.setColor(gfx.kColorBlack)
    local playerScreenX, playerScreenY = Camera.toScreen(Player.x, Player.y)
    for i = 1, #Weapon.list do
        local w = Weapon.list[i]
        local screenX, screenY = Camera.toScreen(w.x, w.y)
        if not w.def.NO_CHAIN then
            drawChain(playerScreenX, playerScreenY, screenX, screenY)
        end
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
