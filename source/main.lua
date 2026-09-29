-- Crank & Slash - nucleo de combate (F1 a F5)
import "CoreLibs/graphics"
import "config"
import "pool"
import "collision"
import "energy"
import "round"
import "player"
import "camera"
import "map"
import "weapon_types"
import "weapon"
import "enemy"
import "projectile"
import "ranged"
import "combat"

local gfx = playdate.graphics

local ANNOUNCE_DURATION = 1.5 -- segundos que se muestra el aviso "Ronda N"

local spawnTimer = 0
local announceTimer = 0
local gameOver = false

local function resetGame()
    Energy.reset()
    Round.reset()
    Player.reset()
    Camera.reset()
    Weapon.reset()
    Enemy.reset()
    Projectile.reset()
    Ranged.reset()
    spawnTimer = 0
    announceTimer = 0
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
        if Round.update(dt) then
            Enemy.reset()
            announceTimer = ANNOUNCE_DURATION
        end
        if announceTimer > 0 then
            announceTimer = announceTimer - dt
        end
        Player.update(dt)
        Camera.update()
        Weapon.update(dt)
        Ranged.update(dt)

        spawnTimer = spawnTimer + dt
        if spawnTimer >= Config.SPAWN_INTERVAL then
            spawnTimer = 0
            Enemy.spawn()
        end

        Enemy.update(dt)
        Projectile.update(dt)
        Combat.update()

        if Player.hp <= 0 then gameOver = true end
    elseif playdate.buttonJustPressed(playdate.kButtonA) then
        resetGame()
    end

    gfx.clear(gfx.kColorWhite)
    Map.draw()
    Enemy.draw()
    Weapon.draw()
    Projectile.draw()
    Player.draw()
    drawHud()
    if announceTimer > 0 then
        local announceText = "Ronda " .. Round.number
        local textWidth = gfx.getTextSize(announceText)
        gfx.drawText(announceText, (Config.SCREEN_W - textWidth) / 2, 100)
    end
    if gameOver then
        gfx.drawText("GAME OVER - presiona A", 110, 110)
    end
end
