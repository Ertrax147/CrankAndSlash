-- Dificultad creciente: a medida que avanzan las rondas, los enemigos aparecen mas seguido
-- y con mas vida. Solo calcula numeros segun la ronda actual (Round.number); quien los usa
-- es main.lua (ritmo de aparicion) y enemy.lua (vida).
Difficulty = {
    SPAWN_STEP = 0.07,         -- cuantos segundos baja el intervalo entre apariciones en cada ronda
    MIN_SPAWN_INTERVAL = 0.3,  -- el intervalo nunca baja de esto
    HP_STEP = 0.12,            -- cuanta vida extra tienen los enemigos en cada ronda (0.12 = +12%)
}

-- Segundos entre un enemigo y el siguiente: parte de Config.SPAWN_INTERVAL en la ronda 1 y baja
function Difficulty.spawnInterval()
    local interval = Config.SPAWN_INTERVAL - Difficulty.SPAWN_STEP * (Round.number - 1)
    return math.max(Difficulty.MIN_SPAWN_INTERVAL, interval)
end

-- Multiplicador de la vida de los enemigos: 1 en la ronda 1 y sube en cada ronda
function Difficulty.hpMult()
    return 1 + Difficulty.HP_STEP * (Round.number - 1)
end
