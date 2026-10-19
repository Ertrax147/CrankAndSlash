-- Avisos de texto que aparecen un momento en el centro de la pantalla: el de la ronda ("Ronda 5 -
-- JEFE!") y el de la ultima mejora elegida. Cada tipo de aviso es una "ranura" con su texto, su
-- tiempo restante y su altura en pantalla.
local gfx = playdate.graphics

Notices = {
    DURATION = 1.5, -- segundos que se muestra cada aviso
}

local slots = {
    round = { text = "", timer = 0, y = 100 },
    upgrade = { text = "", timer = 0, y = 130 },
}

function Notices.reset()
    for _, slot in pairs(slots) do
        slot.timer = 0
    end
end

-- Muestra "text" en la ranura "name" ("round" o "upgrade") durante Notices.DURATION segundos
function Notices.show(name, text)
    local slot = slots[name]
    slot.text = text
    slot.timer = Notices.DURATION
end

-- Descuenta el tiempo de los avisos que se estan mostrando
function Notices.update(dt)
    for _, slot in pairs(slots) do
        if slot.timer > 0 then slot.timer = slot.timer - dt end
    end
end

-- Dibuja los avisos activos, centrados horizontalmente
function Notices.draw()
    for _, slot in pairs(slots) do
        if slot.timer > 0 then
            local textWidth = gfx.getTextSize(slot.text)
            gfx.drawText(slot.text, (Config.SCREEN_W - textWidth) / 2, slot.y)
        end
    end
end
