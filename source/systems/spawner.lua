-- Aparicion de enemigos: cada cuanto sale uno nuevo (segun la dificultad) y que pasa al empezar
-- cada ronda (se borran los enemigos normales y, si toca, llega el jefe).
Spawner = {}

local timer = 0 -- segundos desde el ultimo enemigo que aparecio

function Spawner.reset()
    timer = 0
    -- si la partida empieza en una ronda de jefe (desde la pantalla de pruebas), llega de inmediato
    if Difficulty.isBossRound() then Enemy.spawnBoss() end
end

-- Hace aparecer un enemigo cada Difficulty.spawnInterval() segundos
function Spawner.update(dt)
    timer = timer + dt
    if timer >= Difficulty.spawnInterval() then
        timer = 0
        Enemy.spawn()
    end
end

-- Se llama al empezar una ronda nueva
function Spawner.newRound()
    Enemy.clearNormals() -- el jefe, si sigue vivo, no desaparece
    if Difficulty.isBossRound() and not Enemy.bossAlive() then
        Enemy.spawnBoss()
    end
end
