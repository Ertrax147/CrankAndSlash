-- Fondo del mapa: pasto por todo el mundo infinito, caminos de tierra que serpentean,
-- farolas a lo largo de los caminos y arboledas. Todo se calcula con numeros fijos por celda
-- (no hay azar de verdad), asi el mundo siempre es igual y no hay que guardar nada.
-- Arte: tileset de chuckiecatt (itch.io), convertido a 1-bit.
--
-- Unidades: una "celda" mide TILE_SIZE pixeles (el pasto). Un "medio tile" mide HALF_SIZE
-- (la mitad); los caminos y las farolas se miden en medios tiles para poder ser mas delgados.
local gfx = playdate.graphics

Map = {
    TILE_PIXELS = 16, -- tamano del dibujo original del tile
    SCALE = 2,        -- cuantas veces se agranda el tile de pasto

    -- Caminos
    ROAD_HALF_WIDTH = 1,  -- el camino cubre 2*1+1 = 3 medios tiles (48 px)
    ROAD_SWAY = 5,        -- cuanto se desvia el camino hacia los lados (en medios tiles)
    ROAD_WAVELENGTH = 40, -- cada cuantos medios tiles se repite la curva
    LAMP_SPACING = 16,    -- una farola cada tantos medios tiles a lo largo del camino

    -- Arboledas: el mundo se divide en zonas de GROVE_ZONE celdas; en algunas zonas hay una
    -- arboleda redonda (densa en el centro, rala en el borde) y el resto queda despejado.
    GROVE_ZONE = 16,
    GROVE_MARGIN = 6,       -- el centro queda lejos del borde de la zona (>= radio maximo), para que la arboleda no se corte
    GROVE_PERCENT = 45,     -- % de zonas que tienen arboleda
    GROVE_MIN_RADIUS = 2,   -- arboledas chicas: radio entre MIN y MAX, en celdas
    GROVE_MAX_RADIUS = 4,
    GROVE_BIG_PERCENT = 25, -- % de las arboledas que son grandes (radio BIG_RADIUS o BIG_RADIUS + 1)
    GROVE_BIG_RADIUS = 5,
    GROVE_MAX_CHANCE = 500, -- probabilidad por mil de arbol en el centro de la arboleda
    TREE_CHANCE = 10,       -- probabilidad por mil de un arbol suelto fuera de las arboledas
    TREE_FIRST_PERCENT = 66, -- % de los arboles que usan el primer dibujo (el resto usa el segundo)

    DECOR_ROWS_BELOW = 2, -- filas extra abajo: un arbol de una celda de abajo asoma su copa hacia arriba
}
Map.TILE_SIZE = Map.TILE_PIXELS * Map.SCALE
Map.HALF_SIZE = Map.TILE_SIZE // 2

local TAU = 6.2832

-- Los dos tipos de camino. En los verticales el centro cambia segun la fila; en los
-- horizontales, segun la columna. "spacing" es la separacion entre caminos del mismo tipo,
-- "offset" donde esta el camino 0 y "percent" que porcentaje de los caminos existen de verdad.
local VERTICAL = { salt = 11, offset = 12, spacing = 60, percent = 75 }
local HORIZONTAL = { salt = 23, offset = 13, spacing = 84, percent = 55 }

-- Las imagenes se cargan una sola vez; el pasto se agranda una sola vez (no en cada frame)
local grassTile = gfx.image.new("images/grass_tile"):scaledImage(Map.SCALE)
local dirtHalf = gfx.image.new("images/dirt_half")
-- Arbol con copa en tablero (relleno al 50%) y un brillo arriba: se distingue del pasto, que es
-- claro, y no es negro solido, porque el jugador, las armas y los enemigos son negros y sobre un
-- arbol negro solido desaparecian.
-- Dos dibujos de arbol (el segundo es de copa blanca): se reparten segun TREE_FIRST_PERCENT.
local treeImages = {
    gfx.image.new("images/tree_light"),
    gfx.image.new("images/tree_blanco"),
}
local lampImage = gfx.image.new("images/lamppost")

-- Convierte dos enteros en un numero "al azar" que siempre es el mismo para los mismos valores.
-- Ojo: en la Playdate los enteros son de 32 bits, asi que todas las constantes deben ser menores
-- a 2147483647; si no, Lua las vuelve decimales y los operadores de bits (~, >>) fallan.
local function cellHash(a, b)
    local n = a * 73856093 ~ b * 19349663
    n = (n ~ (n >> 15)) * 1274126177
    n = n ~ (n >> 13)
    return n
end

-- true si el camino numero k de ese tipo existe (el 0 siempre existe, asi hay uno cerca del inicio)
local function roadExists(road, k)
    if k == 0 then return true end
    return cellHash(k, road.salt) % 100 < road.percent
end

-- Centro del camino k en la posicion t a lo largo de el: una linea con una curva suave (seno)
-- cuya fase es distinta para cada camino.
local function roadCenter(road, k, t)
    local phase = (cellHash(k, road.salt + 1000) % 628) / 100
    local sway = math.floor(Map.ROAD_SWAY * math.sin(t * TAU / Map.ROAD_WAVELENGTH + phase) + 0.5)
    return road.offset + k * road.spacing + sway
end

-- Indices k de los caminos que podrian tocar el rango [lo, hi] de medios tiles
local function roadRange(road, lo, hi)
    local reach = Map.ROAD_SWAY + Map.ROAD_HALF_WIDTH
    return (lo - reach - road.offset) // road.spacing, (hi + reach - road.offset) // road.spacing
end

-- true si algun camino toca el rectangulo de medios tiles [hx0..hx1] x [hy0..hy1]
local function roadInRect(hx0, hy0, hx1, hy1)
    local hw = Map.ROAD_HALF_WIDTH
    local kMin, kMax = roadRange(VERTICAL, hx0, hx1)
    for k = kMin, kMax do
        if roadExists(VERTICAL, k) then
            for hy = hy0, hy1 do
                local c = roadCenter(VERTICAL, k, hy)
                if c + hw >= hx0 and c - hw <= hx1 then return true end
            end
        end
    end
    kMin, kMax = roadRange(HORIZONTAL, hy0, hy1)
    for k = kMin, kMax do
        if roadExists(HORIZONTAL, k) then
            for hx = hx0, hx1 do
                local c = roadCenter(HORIZONTAL, k, hx)
                if c + hw >= hy0 and c - hw <= hy1 then return true end
            end
        end
    end
    return false
end

-- Probabilidad por mil de que la celda tenga un arbol: baja en general y alta cerca del centro
-- de una arboleda. Cada zona decide con su propio numero fijo si tiene arboleda, donde esta su
-- centro y que tan grande es.
local function treeChanceAt(cx, cy)
    local chance = Map.TREE_CHANCE
    local zx = cx // Map.GROVE_ZONE
    local zy = cy // Map.GROVE_ZONE
    local h = cellHash(zx * 7 + 1, zy * 13 + 2)
    if h % 100 < Map.GROVE_PERCENT then
        local span = Map.GROVE_ZONE - 2 * Map.GROVE_MARGIN
        local gx = zx * Map.GROVE_ZONE + Map.GROVE_MARGIN + (h >> 7) % span
        local gy = zy * Map.GROVE_ZONE + Map.GROVE_MARGIN + (h >> 13) % span
        local radius = Map.GROVE_MIN_RADIUS + (h >> 19) % (Map.GROVE_MAX_RADIUS - Map.GROVE_MIN_RADIUS + 1)
        if (h >> 23) % 100 < Map.GROVE_BIG_PERCENT then
            radius = Map.GROVE_BIG_RADIUS + (h >> 19) % 2 -- arboleda grande
        end
        local dx = cx - gx
        local dy = cy - gy
        local dist = math.sqrt(dx * dx + dy * dy)
        if dist < radius then
            chance = chance + Map.GROVE_MAX_CHANCE * (1 - dist / radius)
        end
    end
    return chance
end

-- Devuelve la imagen del arbol de esa celda, o nil si no tiene (o si esta encima o pegada a un camino).
-- El mismo numero fijo de la celda decide si hay arbol (con su parte baja) y cual de los dos dibujos
-- es (con una parte mas alta), asi el arbol de cada lugar es siempre el mismo.
local function treeAt(cx, cy)
    local h = cellHash(cx, cy)
    if h % 1000 >= treeChanceAt(cx, cy) then return nil end
    if roadInRect(2 * cx - 2, 2 * cy - 2, 2 * cx + 3, 2 * cy + 3) then return nil end
    if (h >> 10) % 100 < Map.TREE_FIRST_PERCENT then return treeImages[1] end
    return treeImages[2]
end

-- Dibuja la tierra de todos los caminos visibles, un medio tile a la vez
local function drawRoads(firstHx, lastHx, firstHy, lastHy)
    local half = Map.HALF_SIZE
    local hw = Map.ROAD_HALF_WIDTH

    local kMin, kMax = roadRange(VERTICAL, firstHx, lastHx)
    for k = kMin, kMax do
        if roadExists(VERTICAL, k) then
            for hy = firstHy, lastHy do
                local c = roadCenter(VERTICAL, k, hy)
                for hx = c - hw, c + hw do
                    if hx >= firstHx and hx <= lastHx then
                        local screenX, screenY = Camera.toScreen(hx * half, hy * half)
                        dirtHalf:draw(screenX, screenY)
                    end
                end
            end
        end
    end

    kMin, kMax = roadRange(HORIZONTAL, firstHy, lastHy)
    for k = kMin, kMax do
        if roadExists(HORIZONTAL, k) then
            for hx = firstHx, lastHx do
                local c = roadCenter(HORIZONTAL, k, hx)
                for hy = c - hw, c + hw do
                    if hy >= firstHy and hy <= lastHy then
                        local screenX, screenY = Camera.toScreen(hx * half, hy * half)
                        dirtHalf:draw(screenX, screenY)
                    end
                end
            end
        end
    end
end

-- Dibuja una farola cada LAMP_SPACING medios tiles, pegada al borde izquierdo de los caminos
-- verticales y al borde de arriba de los horizontales.
local function drawLamps(firstHx, lastHx, firstHy, lastHy)
    local half = Map.HALF_SIZE
    local hw = Map.ROAD_HALF_WIDTH
    local spacing = Map.LAMP_SPACING
    local w, h = lampImage:getSize()

    local kMin, kMax = roadRange(VERTICAL, firstHx, lastHx)
    local firstRow = ((firstHy + spacing - 1) // spacing) * spacing
    for k = kMin, kMax do
        if roadExists(VERTICAL, k) then
            for hy = firstRow, lastHy, spacing do
                local hx = roadCenter(VERTICAL, k, hy) - hw - 1
                if hx >= firstHx - 1 and hx <= lastHx + 1 then
                    local screenX, screenY = Camera.toScreen(hx * half, hy * half)
                    lampImage:draw(screenX + (half - w) / 2, screenY + half - h)
                end
            end
        end
    end

    kMin, kMax = roadRange(HORIZONTAL, firstHy, lastHy)
    local firstCol = ((firstHx + spacing - 1) // spacing) * spacing
    for k = kMin, kMax do
        if roadExists(HORIZONTAL, k) then
            for hx = firstCol, lastHx, spacing do
                local hy = roadCenter(HORIZONTAL, k, hx) - hw - 1
                if hy >= firstHy - 1 and hy <= lastHy + 1 then
                    local screenX, screenY = Camera.toScreen(hx * half, hy * half)
                    lampImage:draw(screenX + (half - w) / 2, screenY + half - h)
                end
            end
        end
    end
end

-- Dibuja primero el pasto, luego los caminos, luego las farolas y por ultimo los arboles.
-- Las celdas se recorren de arriba hacia abajo, asi lo que esta mas abajo tapa a lo de atras.
function Map.draw()
    local size = Map.TILE_SIZE
    local half = Map.HALF_SIZE

    local firstCx = math.floor((Camera.x - Config.SCREEN_W / 2) / size)
    local lastCx = math.floor((Camera.x + Config.SCREEN_W / 2) / size)
    local firstCy = math.floor((Camera.y - Config.SCREEN_H / 2) / size)
    local lastCy = math.floor((Camera.y + Config.SCREEN_H / 2) / size)

    for cy = firstCy, lastCy do
        for cx = firstCx, lastCx do
            local screenX, screenY = Camera.toScreen(cx * size, cy * size)
            grassTile:draw(screenX, screenY)
        end
    end

    local firstHx = math.floor((Camera.x - Config.SCREEN_W / 2) / half)
    local lastHx = math.floor((Camera.x + Config.SCREEN_W / 2) / half)
    local firstHy = math.floor((Camera.y - Config.SCREEN_H / 2) / half)
    local lastHy = math.floor((Camera.y + Config.SCREEN_H / 2) / half)

    drawRoads(firstHx, lastHx, firstHy, lastHy)
    -- filas extra abajo: las farolas y los arboles son mas altos que su celda y asoman hacia arriba
    drawLamps(firstHx, lastHx, firstHy, lastHy + 2 * Map.DECOR_ROWS_BELOW)

    for cy = firstCy, lastCy + Map.DECOR_ROWS_BELOW do
        for cx = firstCx - 1, lastCx + 1 do
            local tree = treeAt(cx, cy)
            if tree then
                local screenX, screenY = Camera.toScreen(cx * size, cy * size)
                local w, h = tree:getSize()
                -- centrado en la celda y con la base apoyada en el borde de abajo
                tree:draw(screenX + (size - w) / 2, screenY + size - h)
            end
        end
    end
end
