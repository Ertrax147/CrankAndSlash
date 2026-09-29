-- Camara: sigue al jugador para que quede centrado en pantalla mientras el mundo se mueve.
Camera = {
    x = 0,
    y = 0,
}

function Camera.reset()
    Camera.x = Player.x
    Camera.y = Player.y
end

-- Se llama cada frame para que la camara quede siempre sobre el jugador
function Camera.update()
    Camera.x = Player.x
    Camera.y = Player.y
end

-- Convierte una posicion del mundo a donde dibujarla en pantalla:
-- resta la posicion de la camara y centra en la pantalla (0,0 de camara = centro de pantalla)
function Camera.toScreen(worldX, worldY)
    local screenX = worldX - Camera.x + Config.SCREEN_W / 2
    local screenY = worldY - Camera.y + Config.SCREEN_H / 2
    return screenX, screenY
end
