-- Interfaz fija de la partida: vida, ronda, tiempo, barra de energia de la manivela, nivel y
-- barra de experiencia. Solo dibuja; los datos los lee de los demas modulos.
local gfx = playdate.graphics

Hud = {
    -- barra de experiencia: abajo, a la derecha de la barra de energia
    XP_BAR_X = 160,
    XP_BAR_Y = 226,
    XP_BAR_W = 236,
    XP_BAR_H = 10,
}

function Hud.draw()
    gfx.setColor(gfx.kColorBlack)
    gfx.drawText("HP: " .. Player.hp .. "/" .. Stats.maxHp(), 4, 4)
    gfx.drawText("Ronda: " .. Round.number, 170, 4)
    gfx.drawText("Tiempo: " .. math.ceil(Round.timeLeft), 300, 4)
    -- barra de energia de la manivela
    gfx.drawRect(4, 226, 100, 10)
    gfx.fillRect(4, 226, 100 * Energy.ratio(), 10)
    -- nivel y barra de experiencia
    gfx.drawText("Nv. " .. Xp.level, 110, 220)
    gfx.drawRect(Hud.XP_BAR_X, Hud.XP_BAR_Y, Hud.XP_BAR_W, Hud.XP_BAR_H)
    gfx.fillRect(Hud.XP_BAR_X, Hud.XP_BAR_Y, Hud.XP_BAR_W * Xp.ratio(), Hud.XP_BAR_H)
end
