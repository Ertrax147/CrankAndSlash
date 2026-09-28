-- Crank & Slash - nucleo de combate (F1 a F5)
import "CoreLibs/graphics"
import "config"
import "pool"
import "collision"
import "energy"
import "round"
import "player"
import "weapon"
import "enemy"
import "combat"

local gfx = playdate.graphics

local spawnTimer = 0
local gameOver = false

local function resetGame()
    Energy.reset()
    Round.reset()
    Player.reset()
    Weapon.reset()
    Enemy.reset()
    spawnTimer = 0
    gameOver = false
end

local function drawHud()
    gfx.setColor(gfx.kColorBlack)
    gfx.drawText("HP: " .. Player.hp, 4, 4)
    gfx.drawText("Ronda: " .. Round.number, 170, 4)
    gfx.drawText("Tiempo: " .. math.ceil(Round.timeLeft), 300, 4)
    -- barra de energia de la manivela
    gfx.drawRect(4, 226, 100, 10)
    gfx.fillRect(4, 226, 100 * Energy.ratio(), 10)
end

resetGame()

function playdate.update()
    local dt = Config.DT

    if not gameOver then
        Energy.update(dt)
        Round.update(dt)
        Player.update(dt)
        Weapon.update(dt)

        spawnTimer = spawnTimer + dt
        if spawnTimer >= Config.SPAWN_INTERVAL then
            spawnTimer = 0
            Enemy.spawn()
        end

        Enemy.update(dt)
        Combat.update()

        if Player.hp <= 0 then gameOver = true end
    elseif playdate.buttonJustPressed(playdate.kButtonA) then
        resetGame()
    end

    gfx.clear(gfx.kColorWhite)
    Enemy.draw()
    Weapon.draw()
    Player.draw()
    drawHud()
    if gameOver then
        gfx.drawText("GAME OVER - presiona A", 110, 110)
    end
end
