-- Menu de subida de nivel: cuando el jugador sube de nivel el juego se pausa y se ofrecen unas
-- mejoras (Upgrades) para elegir con arriba/abajo y A. main.lua solo le pregunta si esta abierto
-- (para pausar el juego), le avisa cada cuadro que revise si hubo subida de nivel, y lo
-- actualiza y dibuja.
local gfx = playdate.graphics

LevelMenu = {}

local choices = nil   -- las mejoras que se ofrecen ahora (lista de Upgrades), o nil si el menu esta cerrado
local cursor = 1      -- cual de las opciones esta seleccionada
local pending = 0     -- niveles subidos que todavia no tienen su menu (si se sube mas de uno de golpe)
local lastLevel = 1   -- nivel del cuadro anterior, para detectar cuando sube

-- Cierra el menu y olvida todo (al empezar o reiniciar la partida; llamar despues de Xp.reset)
function LevelMenu.reset()
    choices = nil
    cursor = 1
    pending = 0
    lastLevel = Xp.level
end

-- true si el menu esta abierto (mientras tanto el juego esta en pausa)
function LevelMenu.isOpen()
    return choices ~= nil
end

-- Revisa si el jugador subio de nivel desde el cuadro anterior y deja pendiente un menu por cada nivel
function LevelMenu.detectLevelUp()
    if Xp.level > lastLevel then
        pending = pending + (Xp.level - lastLevel)
        lastLevel = Xp.level
    end
end

-- Abre el menu: elige las opciones al azar y gasta uno de los niveles pendientes
local function open()
    choices = Upgrades.pickChoices()
    cursor = 1
    pending = pending - 1
end

-- Abre el menu si quedan niveles pendientes
function LevelMenu.openIfPending()
    if pending > 0 then open() end
end

-- Mientras el menu esta abierto: arriba/abajo mueve el cursor y A elige la mejora.
-- Si se subieron varios niveles de golpe, al elegir se abre el menu del siguiente.
function LevelMenu.update()
    if playdate.buttonJustPressed(playdate.kButtonUp) then cursor = cursor - 1 end
    if playdate.buttonJustPressed(playdate.kButtonDown) then cursor = cursor + 1 end
    if cursor < 1 then cursor = #choices end
    if cursor > #choices then cursor = 1 end

    if playdate.buttonJustPressed(playdate.kButtonA) then
        local chosen = choices[cursor]
        chosen.apply()
        Notices.show("upgrade", chosen.name .. ": " .. chosen.text)
        choices = nil
        if pending > 0 then open() end
    end
end

-- Dibuja el cuadro del menu encima de todo lo demas (nombre y descripcion de cada mejora)
function LevelMenu.draw()
    local boxX, boxY, boxW, boxH = 20, 6, 360, 228
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(boxX, boxY, boxW, boxH)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawRect(boxX, boxY, boxW, boxH)
    gfx.drawRect(boxX + 2, boxY + 2, boxW - 4, boxH - 4)

    local title = "Nivel " .. Xp.level .. " - elige una mejora"
    local titleWidth = gfx.getTextSize(title)
    gfx.drawText(title, (Config.SCREEN_W - titleWidth) / 2, boxY + 10)

    for i = 1, #choices do
        local top = boxY + 36 + (i - 1) * 50
        gfx.drawText(choices[i].name, boxX + 24, top)
        gfx.drawText(choices[i].text, boxX + 24, top + 20)
        if i == cursor then
            gfx.drawRect(boxX + 10, top - 4, boxW - 20, 46) -- marco alrededor de la opcion elegida
        end
    end

    gfx.drawText("Arriba/Abajo: mover   A: elegir", boxX + 70, boxY + boxH - 26)
end
