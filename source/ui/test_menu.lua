-- Pantalla de pruebas (solo para desarrollo): aparece al abrir el juego si Config.DEBUG_MENU es true.
-- Permite elegir con que empezar la partida (personaje, etc.) sin recompilar. Arriba/abajo cambia de
-- fila, izquierda/derecha cambia el valor y A empieza. main.lua solo la actualiza, la dibuja y, al
-- empezar, llama a TestMenu.apply() para aplicar lo elegido.
local gfx = playdate.graphics

TestMenu = {}

local ROW_HEIGHT = 21   -- alto de cada fila
local VISIBLE_ROWS = 8  -- cuantas filas caben en la pantalla; si hay mas, la lista se desplaza
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
    label = "Armas extra", index = 1,
    options = {
        { text = "Ninguna", value = { pistol = false, whip = false, lightning = false } },
        { text = "Pistola", value = { pistol = true, whip = false, lightning = false } },
        { text = "Latigo", value = { pistol = false, whip = true, lightning = false } },
        { text = "Rayo", value = { pistol = false, whip = false, lightning = true } },
        { text = "Todas", value = { pistol = true, whip = true, lightning = true } },
    },
    apply = function(extras)
        Ranged.startUnlocked = extras.pistol
        Whip.startUnlocked = extras.whip
        Lightning.startUnlocked = extras.lightning
    end,
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
rows[7] = {
    label = "Mecanismo", index = 1,
    options = { { text = "Manivela", value = "CRANK" }, { text = "Volante", value = "WHEEL" } },
    apply = function(mechanism) Player.setMechanism(mechanism) end, -- despues del personaje: recarga sus dibujos
}
rows[8] = {
    label = "Latigo", index = 1,
    options = {
        { text = "Enemigo cercano", value = "NEAREST" },
        { text = "Alternar", value = "ALTERNATE" },
        { text = "Mirada", value = "FACING" },
    },
    apply = function(mode) Whip.aimMode = mode end,
}
rows[9] = {
    label = "Rayo", index = 1,
    options = { { text = "Ramas", value = "BRANCHES" }, { text = "Simple", value = "SIMPLE" } },
    apply = function(style) Lightning.style = style end,
}
rows[10] = {
    label = "Suelo", index = 1,
    options = {
        { text = "Pasto", value = "GRASS" }, { text = "Liso", value = "CLEAN" }, { text = "Puntos", value = "DOTS" },
        { text = "Tierra", value = "DIRT" }, { text = "Adoquin", value = "STONE" }, { text = "Arena", value = "SAND" },
    },
    apply = function(name) Map.setFloor(name) end,
}
rows[11] = {
    label = "Latigo dibujo", index = 1,
    options = { { text = "Arco", value = "ARC" }, { text = "Linea", value = "LINE" } },
    apply = function(style) Whip.drawStyle = style end,
}
rows[12] = {
    label = "Efectos golpe", index = 1,
    options = { { text = "No", value = false }, { text = "Si", value = true } },
    apply = function(enabled) Effects.startEnabled = enabled end,
}
local cursor = 1 -- fila seleccionada
local scroll = 0 -- cuantas filas de arriba estan escondidas (la lista se desplaza si hay mas de VISIBLE_ROWS)

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
    -- mantiene la fila elegida dentro de las que se ven
    if cursor <= scroll then scroll = cursor - 1 end
    if cursor > scroll + VISIBLE_ROWS then scroll = cursor - VISIBLE_ROWS end

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
    gfx.drawText(title, (Config.SCREEN_W - titleWidth) / 2, 6)

    for slot = 1, math.min(VISIBLE_ROWS, #rows) do
        local i = scroll + slot
        local top = 30 + (slot - 1) * ROW_HEIGHT
        local row = rows[i]
        gfx.drawText(row.label, 24, top)
        gfx.drawText("< " .. row.options[row.index].text .. " >", 130, top)
        if i == cursor then
            gfx.drawRect(16, top - 2, 262, ROW_HEIGHT) -- marco alrededor de la fila elegida
        end
    end

    -- avisa si hay filas escondidas arriba o abajo
    if scroll > 0 then gfx.drawText("^", 284, 30) end
    if scroll + VISIBLE_ROWS < #rows then gfx.drawText("v", 284, 30 + (VISIBLE_ROWS - 1) * ROW_HEIGHT) end

    drawPreview()
    gfx.drawText("Arriba/Abajo  Izq/Der  A: empezar", 24, Config.SCREEN_H - 28)
end
