-- Personaje: se mueve con la cruceta
local gfx = playdate.graphics

Player = {
    RADIUS = 8,
    SPEED = 90,        -- pixeles por segundo
    MAX_HP = 5,
    INVULN_TIME = 1.0, -- segundos sin recibir dano despues de un golpe
}

function Player.reset()
    Player.x = Config.SCREEN_W / 2
    Player.y = Config.SCREEN_H / 2
    Player.hp = Player.MAX_HP
    Player.invuln = 0
end

function Player.update(dt)
    local dx, dy = 0, 0
    if playdate.buttonIsPressed(playdate.kButtonLeft) then dx = dx - 1 end
    if playdate.buttonIsPressed(playdate.kButtonRight) then dx = dx + 1 end
    if playdate.buttonIsPressed(playdate.kButtonUp) then dy = dy - 1 end
    if playdate.buttonIsPressed(playdate.kButtonDown) then dy = dy + 1 end

    -- en diagonal no debe ir mas rapido
    if dx ~= 0 and dy ~= 0 then
        dx = dx * 0.7071
        dy = dy * 0.7071
    end

    Player.x = Player.x + dx * Player.SPEED * dt
    Player.y = Player.y + dy * Player.SPEED * dt

    -- limites de la arena
    local r = Player.RADIUS
    if Player.x < r then Player.x = r end
    if Player.x > Config.SCREEN_W - r then Player.x = Config.SCREEN_W - r end
    if Player.y < r then Player.y = r end
    if Player.y > Config.SCREEN_H - r then Player.y = Config.SCREEN_H - r end

    if Player.invuln > 0 then
        Player.invuln = Player.invuln - dt
        if Player.invuln < 0 then Player.invuln = 0 end
    end
end

function Player.hurt(amount)
    if Player.invuln > 0 then return end
    Player.hp = Player.hp - amount
    Player.invuln = Player.INVULN_TIME
end

function Player.draw()
    -- parpadea mientras es invulnerable
    if Player.invuln > 0 and math.floor(Player.invuln * 10) % 2 == 0 then return end
    gfx.setColor(gfx.kColorBlack)
    gfx.fillCircleAtPoint(Player.x, Player.y, Player.RADIUS)
end
