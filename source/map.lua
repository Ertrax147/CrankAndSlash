-- Fondo del mapa: una grilla de puntos, para notar que la camara se mueve.
local gfx = playdate.graphics

Map = {
    GRID_SPACING = 40, -- distancia en pixeles entre puntos, en coordenadas de mundo
    DOT_RADIUS = 1,
}

-- Dibuja solo los puntos de la grilla que caen dentro de lo que se ve en pantalla.
function Map.draw()
    gfx.setColor(gfx.kColorBlack)
    local spacing = Map.GRID_SPACING

    -- primer punto visible, alineado a la grilla del mundo (no a la pantalla),
    -- para que los puntos no "salten" al moverse la camara
    local startWorldX = math.floor((Camera.x - Config.SCREEN_W / 2) / spacing) * spacing
    local startWorldY = math.floor((Camera.y - Config.SCREEN_H / 2) / spacing) * spacing
    local endWorldX = Camera.x + Config.SCREEN_W / 2
    local endWorldY = Camera.y + Config.SCREEN_H / 2

    for worldX = startWorldX, endWorldX, spacing do
        for worldY = startWorldY, endWorldY, spacing do
            local screenX, screenY = Camera.toScreen(worldX, worldY)
            gfx.fillCircleAtPoint(screenX, screenY, Map.DOT_RADIUS)
        end
    end
end
