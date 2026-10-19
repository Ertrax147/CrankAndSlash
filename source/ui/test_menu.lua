-- Pantalla de pruebas (solo para desarrollo): aparece al abrir el juego si Config.DEBUG_MENU es true.
-- Permite elegir con que empezar la partida (personaje, etc.) sin recompilar. Arriba/abajo cambia de
-- fila, izquierda/derecha cambia el valor y A empieza. main.lua solo la actualiza, la dibuja y, al
-- empezar, llama a TestMenu.apply() para aplicar lo elegido.
local gfx = playdate.graphics

TestMenu = {}

local ROW_HEIGHT = 24   -- alto de cada fila (con 7 filas, mas alto no cabe en la pantalla de 240)
local PREVIEW_SCALE = 2 -- el dibujo del personaje se muestra al doble de tamano
local previews = {}     -- dibujos ampliados del personaje, guardados para no crearlos en cada cuadro

-- Cada fila es una opcion: label (nombre), options (lista de { text, value }: lo que se ve y lo que
-- vale), index (cual esta elegida) y apply(value) (lo que hace al empezar la partida).
-- Para agregar una opcion nueva se agrega otra fila aqui. La primera fila debe ser el personaje
-- (el dibujo de la derecha sigue a esa fila).
local rows = {}

-- Arma una lista de opciones a partir de una lista de numeros (el texto es el mismo numero)
local function numberOptions(numbers)
    local options = {}
    for i = 1, #numbers do options[i] = { text = tostring(numbers[i]), value = numbers[i] } end
    return options
end

-- Opciones de personaje: una por cada uno de Characters.LIST
local characterOptions = {}
for i = 1, #Characters.LIST do
    characterOptions[i] = { text = Characters.LIST[i].NAME, value = Characters.LIST[i] }
end

rows[1] = {
    label = "Personaje", options = characterOptions, index = 1,
    apply = function(character) Player.setCharacter(character) end,
}
rows[2] = {
    label = "Duracion", options = numberOptions({ 10, 15, 20, 30, 45, 60 }), index = 4,
    apply = function(seconds) Round.TIME_LIMIT = seconds end,
}
rows[3] = {
    label = "Ronda inicial", options = numberOptions({ 1, 2, 3, 4, 5, 6, 10 }), index = 1,
    apply = function(number) Round.startNumber = number end, -- en 5 o 10 empieza con el jefe
}
rows[4] = {
    label = "Arma", index = 1,
    options = {
        { text = "Espada larga", value = "ESPADA_LARGA" },
        { text = "Maza", value = "MAZA" },
        { text = "Mandoble", value = "MANDOBLE" },
    },
    apply = function(typeName) Weapon.startingType = typeName end,
}
rows[5] = {
    label = "Pistola", index = 1,
    options = { { text = "No", value = false }, { text = "Si", value = true } },
    apply = function(unlocked) Ranged.startUnlocked = unlocked end,
}
rows[6] = {
    label = "Rayos", index = 1,
    options = {
        { text = "Cuerpo", value = "BODY" },
        { text = "Antena", value = "ANTENNA" },
        { text = "Ambos", value = "BOTH" },
        { text = "Ninguno", value = "NONE" },
    },
    apply = function(mode) Player.boltMode = mode end,
}
local cursor = 1 -- fila seleccionada

-- Deja elegido el personaje que indica Config.DEBUG_CHARACTER (se llama al abrir el juego)
function TestMenu.reset()
    for i = 1, #characterOptions do
        if characterOptions[i].value == Characters[Config.DEBUG_CHARACTER] then rows[1].index = i end
    end
end

-- Mueve el cursor y cambia los valores. Devuelve true el cuadro en que se aprieta A (empezar).
function TestMenu.update()
    if playdate.buttonJustPressed(playdate.kButtonUp) then cursor = cursor - 1 end
    if playdate.buttonJustPressed(playdate.kButtonDown) then cursor = cursor + 1 end
    if cursor < 1 then cursor = #rows end
    if cursor > #rows then cursor = 1 end

    local row = rows[cursor]
    if playdate.buttonJustPressed(playdate.kButtonLeft) then row.index = row.index - 1 end
    if playdate.buttonJustPressed(playdate.kButtonRight) then row.index = row.index + 1 end
    -- al pasar del ultimo valor vuelve al primero y al reves
    if row.index < 1 then row.index = #row.options end
    if row.index > #row.options then row.index = 1 end

    return playdate.buttonJustPressed(playdate.kButtonA)
end

-- Aplica todo lo elegido (se llama justo antes de empezar la partida)
function TestMenu.apply()
    for i = 1, #rows do rows[i].apply(rows[i].options[rows[i].index].value) end
end

-- Dibuja el dibujo ampliado del personaje elegido, a la derecha
local function drawPreview()
    local character = rows[1].options[rows[1].index].value
    if previews[character] == nil then
        previews[character] = gfx.image.new(character.SPRITE .. "_1"):scaledImage(PREVIEW_SCALE)
    end
    local image = previews[character]
    local w, h = image:getSize()
    image:draw(338 - w / 2, 110 - h / 2)
end

-- Dibuja la pantalla: el titulo, una linea por opcion (la elegida con marco) y el dibujo del personaje
function TestMenu.draw()
    gfx.clear(gfx.kColorWhite)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawRect(4, 4, Config.SCREEN_W - 8, Config.SCREEN_H - 8)

    local title = "MODO PRUEBAS"
    local titleWidth = gfx.getTextSize(title)
    gfx.drawText(title, (Config.SCREEN_W - titleWidth) / 2, 10)

    for i = 1, #rows do
        local top = 36 + (i - 1) * ROW_HEIGHT
        local row = rows[i]
        gfx.drawText(row.label, 24, top)
        gfx.drawText("< " .. row.options[row.index].text .. " >", 130, top)
        if i == cursor then
            gfx.drawRect(16, top - 3, 262, ROW_HEIGHT) -- marco alrededor de la fila elegida
        end
    end

    drawPreview()
    gfx.drawText("Arriba/Abajo  Izq/Der  A: empezar", 24, Config.SCREEN_H - 28)
end
