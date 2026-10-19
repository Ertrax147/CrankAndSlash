-- Fondo del mapa: prueba con un tile de pasto (baldosa de 16x16) en vez de la grilla de puntos.
-- EXPERIMENTAL - rama experimento/tileset-mapa, no es parte del plan todavia.
local gfx = playdate.graphics

Map = {
    TILE_SIZE = 16, -- tamano del tile, en pixeles de mundo
}

local grassTile = gfx.image.new("images/grass_tile")

-- Dibuja el tile repetido, solo el area que cae dentro de lo que se ve en pantalla.
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
