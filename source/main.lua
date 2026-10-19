-- Crank & Slash - nucleo de combate (F1 a F5)
import "CoreLibs/graphics"
import "config"
import "pool"
import "collision"
import "energy"
import "round"
import "xp"
import "stats"
import "player"
import "camera"
import "map"
import "weapon_types"
import "weapon"
import "enemy"
import "gems"
import "projectile"
import "ranged"
import "combat"

local gfx = playdate.graphics

local ANNOUNCE_DURATION = 1.5 -- segundos que se muestra el aviso "Ronda N" o "Nivel N"

-- Barra de experiencia: abajo, a la derecha de la barra de energia
local XP_BAR_X = 160
local XP_BAR_Y = 226
local XP_BAR_W = 236
local XP_BAR_H = 10

local spawnTimer = 0
local announceTimer = 0
local levelTimer = 0  -- tiempo que queda mostrando el aviso "Nivel N"
local lastLevel = 1   -- nivel del cuadro anterior, para detectar cuando sube
local gameOver = false

local function resetGame()
    Energy.reset()
    Round.reset()
    Xp.reset()
    Stats.reset()
    Player.reset()
    Camera.reset()
    Weapon.reset()
    Enemy.reset()
    Gems.reset()
    Projectile.reset()
    Ranged.reset()
    spawnTimer = 0
    announceTimer = 0
    levelTimer = 0
    lastLevel = Xp.level
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
    -- nivel y barra de experiencia
    gfx.drawText("Nv. " .. Xp.level, 110, 220)
    gfx.drawRect(XP_BAR_X, XP_BAR_Y, XP_BAR_W, XP_BAR_H)
    gfx.fillRect(XP_BAR_X, XP_BAR_Y, XP_BAR_W * Xp.ratio(), XP_BAR_H)
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
        Gems.update()

        if Xp.level > lastLevel then
            lastLevel = Xp.level
            levelTimer = ANNOUNCE_DURATION
        end
        if levelTimer > 0 then
            levelTimer = levelTimer - dt
        end

        if Player.hp <= 0 then gameOver = true end
    elseif playdate.buttonJustPressed(playdate.kButtonA) then
        resetGame()
    end

    gfx.clear(gfx.kColorWhite)
    Map.draw()
    Gems.draw()
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
    if levelTimer > 0 then
        local levelText = "Nivel " .. Xp.level
        local levelWidth = gfx.getTextSize(levelText)
        gfx.drawText(levelText, (Config.SCREEN_W - levelWidth) / 2, 130)
    end
    if gameOver then
        gfx.drawText("GAME OVER - presiona A", 110, 110)
    end
end
