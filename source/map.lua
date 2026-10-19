-- Fondo del mapa: un tile de pasto repetido por todo el mundo infinito.
-- Arte: tileset de chuckiecatt (itch.io), convertido a 1-bit.
local gfx = playdate.graphics

Map = {
    TILE_PIXELS = 16, -- tamano del dibujo original del tile
    SCALE = 2,        -- cuantas veces se agranda el tile para que se vea mas grande
}
Map.TILE_SIZE = Map.TILE_PIXELS * Map.SCALE -- tamano del tile en pixeles de mundo

-- Se agranda una sola vez al cargar (no en cada frame) para no gastar rendimiento
local grassTile = gfx.image.new("images/grass_tile"):scaledImage(Map.SCALE)

-- Dibuja el tile repetido, solo el area que cae dentro de lo que se ve en pantalla.
-- Las posiciones se alinean a la grilla del mundo, para que no "salten" al moverse la camara.
function Map.draw()
    local size = Map.TILE_SIZE

    local startWorldX = math.floor((Camera.x - Config.SCREEN_W / 2) / size) * size
    local startWorldY = math.floor((Camera.y - Config.SCREEN_H / 2) / size) * size
    local endWorldX = Camera.x + Config.SCREEN_W / 2
    local endWorldY = Camera.y + Config.SCREEN_H / 2

    for worldX = startWorldX, endWorldX, size do
        for worldY = startWorldY, endWorldY, size do
            local screenX, screenY = Camera.toScreen(worldX, worldY)
            grassTile:draw(screenX, screenY)
        end
    end
end
