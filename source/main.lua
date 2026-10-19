-- Crank & Slash: conecta todos los modulos y define el bucle del juego (playdate.update).
-- La logica de cada cosa vive en su carpeta: core/, world/, data/, entities/, systems/ y ui/.
import "CoreLibs/graphics"
import "core/config"
import "core/pool"
import "core/collision"
import "systems/energy"
import "systems/round"
import "systems/difficulty"
import "systems/xp"
import "systems/stats"
import "data/upgrades"
import "entities/player"
import "world/camera"
import "world/map"
import "data/weapon_types"
import "entities/weapon"
import "data/enemy_types"
import "entities/enemy"
import "entities/gems"
import "entities/projectile"
import "systems/ranged"
import "systems/combat"
import "systems/spawner"
import "ui/hud"
import "ui/debug"
import "ui/notices"
import "ui/level_menu"

local gfx = playdate.graphics

local gameOver = false

-- Deja el juego como al empezar (se llama al arrancar y al reiniciar despues de morir)
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
    Notices.reset()
    Spawner.reset()
    LevelMenu.reset() -- despues de Xp.reset: toma el nivel inicial
    gameOver = false
end

resetGame()

function playdate.update()
    local dt = Config.DT

    if LevelMenu.isOpen() then
        LevelMenu.update() -- con el menu abierto el juego esta en pausa
    elseif not gameOver then
        Energy.update(dt)
        if Round.update(dt) then
            Spawner.newRound()
            local roundText = "Ronda " .. Round.number
            if Difficulty.isBossRound() then roundText = roundText .. " - JEFE!" end
            Notices.show("round", roundText)
        end
        Notices.update(dt)
        Player.update(dt)
        Camera.update()
        Weapon.update(dt)
        Ranged.update(dt)

        Spawner.update(dt)
        Enemy.update(dt)
        Projectile.update(dt)
        Combat.update()
        Gems.update()

        LevelMenu.detectLevelUp()
        if Player.hp <= 0 then gameOver = true end
        if not gameOver then LevelMenu.openIfPending() end
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
    if Config.DEBUG_HITBOXES then DebugDraw.hitboxes() end
    Hud.draw()
    Notices.draw()
    if gameOver then
        gfx.drawText("GAME OVER - presiona A", 110, 110)
    end
    if LevelMenu.isOpen() then
        LevelMenu.draw()
    end
end
