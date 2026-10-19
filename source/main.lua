-- Crank & Slash - nucleo de combate (F1 a F5)
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

local gfx = playdate.graphics

local ANNOUNCE_DURATION = 1.5 -- segundos que se muestra el aviso "Ronda N"

-- Barra de experiencia: abajo, a la derecha de la barra de energia
local XP_BAR_X = 160
local XP_BAR_Y = 226
local XP_BAR_W = 236
local XP_BAR_H = 10

local spawnTimer = 0
local announceTimer = 0
local lastLevel = 1   -- nivel del cuadro anterior, para detectar cuando sube
local gameOver = false

-- Menu de subida de nivel: mientras "choices" no sea nil el juego esta en pausa y se muestra el menu
local choices = nil      -- las mejoras que se ofrecen ahora (lista de Upgrades), o nil si no hay menu
local cursor = 1         -- cual de las opciones esta seleccionada
local pendingLevels = 0  -- niveles subidos que todavia no tienen su menu (si se sube mas de uno de golpe)
local upgradeMessage = "" -- aviso de la ultima mejora elegida, para confirmar que se aplico
local upgradeTimer = 0    -- tiempo que queda mostrando ese aviso

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
    lastLevel = Xp.level
    choices = nil
    cursor = 1
    pendingLevels = 0
    upgradeTimer = 0
    gameOver = false
end

local function drawHud()
    gfx.setColor(gfx.kColorBlack)
    gfx.drawText("HP: " .. Player.hp .. "/" .. Stats.maxHp(), 4, 4)
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

-- Depuracion (Config.DEBUG_HITBOXES): dibuja los circulos que usa el juego para las colisiones,
-- para comprobar que el dano y los golpes coinciden con lo que se ve en pantalla.
local function drawHitboxes()
    gfx.setColor(gfx.kColorBlack)
    local playerX, playerY = Camera.toScreen(Player.x, Player.y)
    gfx.drawCircleAtPoint(playerX, playerY, Player.RADIUS)
    local enemies = Enemy.pool.items
    for i = 1, #enemies do
        local e = enemies[i]
        if e.active then
            local x, y = Camera.toScreen(e.x, e.y)
            gfx.drawCircleAtPoint(x, y, e.def.RADIUS)
        end
    end
    for i = 1, #Weapon.list do
        local w = Weapon.list[i]
        for k = 1, #w.hits do
            local hit = w.hits[k]
            local x, y = Camera.toScreen(hit.x, hit.y)
            gfx.drawCircleAtPoint(x, y, hit.r)
        end
    end
    local projectiles = Projectile.pool.items
    for i = 1, #projectiles do
        local p = projectiles[i]
        if p.active then
            local x, y = Camera.toScreen(p.x, p.y)
            gfx.drawCircleAtPoint(x, y, Projectile.RADIUS)
        end
    end
end

-- Abre el menu de mejoras: elige las opciones al azar y gasta uno de los niveles pendientes
local function openLevelMenu()
    choices = Upgrades.pickChoices()
    cursor = 1
    pendingLevels = pendingLevels - 1
end

-- Mientras el menu esta abierto el juego no avanza: arriba/abajo mueve el cursor y A elige.
-- Si se subieron varios niveles de golpe, al elegir se abre el menu del siguiente.
local function updateLevelMenu()
    if playdate.buttonJustPressed(playdate.kButtonUp) then cursor = cursor - 1 end
    if playdate.buttonJustPressed(playdate.kButtonDown) then cursor = cursor + 1 end
    if cursor < 1 then cursor = #choices end
    if cursor > #choices then cursor = 1 end

    if playdate.buttonJustPressed(playdate.kButtonA) then
        choices[cursor].apply()
        upgradeMessage = choices[cursor].name .. ": " .. choices[cursor].text
        upgradeTimer = ANNOUNCE_DURATION
        choices = nil
        if pendingLevels > 0 then openLevelMenu() end
    end
end

-- Dibuja el cuadro del menu encima de todo lo demas (nombre y descripcion de cada mejora)
local function drawLevelMenu()
    local boxX, boxY, boxW, boxH = 20, 6, 360, 228
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(boxX, boxY, boxW, boxH)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawRect(boxX, boxY, boxW, boxH)
    gfx.drawRect(boxX + 2, boxY + 2, boxW - 4, boxH - 4)

    local title = "Nivel " .. Xp.level .. " - elige una mejora"
    local titleWidth = gfx.getTextSize(title)
    gfx.drawText(title, (Config.SCREEN_W - titleWidth) / 2, boxY + 10)

    for i = 1, #choices do
        local top = boxY + 36 + (i - 1) * 50
        gfx.drawText(choices[i].name, boxX + 24, top)
        gfx.drawText(choices[i].text, boxX + 24, top + 20)
        if i == cursor then
            gfx.drawRect(boxX + 10, top - 4, boxW - 20, 46) -- marco alrededor de la opcion elegida
        end
    end

    gfx.drawText("Arriba/Abajo: mover   A: elegir", boxX + 70, boxY + boxH - 26)
end

resetGame()

function playdate.update()
    local dt = Config.DT

    if choices then
        updateLevelMenu()
    elseif not gameOver then
        Energy.update(dt)
        if Round.update(dt) then
            Enemy.clearNormals() -- el jefe, si sigue vivo, no desaparece
            announceTimer = ANNOUNCE_DURATION
            if Difficulty.isBossRound() and not Enemy.bossAlive() then Enemy.spawnBoss() end
        end
        if announceTimer > 0 then
            announceTimer = announceTimer - dt
        end
        if upgradeTimer > 0 then
            upgradeTimer = upgradeTimer - dt
        end
        Player.update(dt)
        Camera.update()
        Weapon.update(dt)
        Ranged.update(dt)

        spawnTimer = spawnTimer + dt
        if spawnTimer >= Difficulty.spawnInterval() then
            spawnTimer = 0
            Enemy.spawn()
        end

        Enemy.update(dt)
        Projectile.update(dt)
        Combat.update()
        Gems.update()

        if Xp.level > lastLevel then
            pendingLevels = pendingLevels + (Xp.level - lastLevel)
            lastLevel = Xp.level
        end

        if Player.hp <= 0 then gameOver = true end
        if not gameOver and pendingLevels > 0 then openLevelMenu() end
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
    if Config.DEBUG_HITBOXES then drawHitboxes() end
    drawHud()
    if announceTimer > 0 then
        local announceText = "Ronda " .. Round.number
        if Difficulty.isBossRound() then announceText = announceText .. " - JEFE!" end
        local textWidth = gfx.getTextSize(announceText)
        gfx.drawText(announceText, (Config.SCREEN_W - textWidth) / 2, 100)
    end
    if upgradeTimer > 0 then
        local upgradeWidth = gfx.getTextSize(upgradeMessage)
        gfx.drawText(upgradeMessage, (Config.SCREEN_W - upgradeWidth) / 2, 130)
    end
    if gameOver then
        gfx.drawText("GAME OVER - presiona A", 110, 110)
    end
    if choices then
        drawLevelMenu()
    end
end
