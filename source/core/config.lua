-- Constantes generales del juego
Config = {
    SCREEN_W = 400,
    SCREEN_H = 240,
    DT = 1 / 30,          -- el Playdate corre a 30 fps por defecto
    SPAWN_INTERVAL = 1.0, -- segundos entre enemigos en la ronda 1 (despues baja, ver difficulty.lua)
    DEBUG_MENU = true,      -- true: al abrir el juego aparece la pantalla de pruebas (ver ui/test_menu.lua)
    DEBUG_CHARACTER = "CIENTIFICO", -- personaje con el que se juega (nombre en data/characters.lua)
    DEBUG_HITBOXES = false, -- true: dibuja los circulos de colision (jugador, enemigos, armas y proyectiles)
}
