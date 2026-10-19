-- Dificultad creciente: a medida que avanza la partida, los enemigos aparecen mas seguido
-- y con mas vida, y cada cierto nivel llega un jefe. Solo calcula numeros segun el "nivel de
-- dificultad" (Difficulty.level); quien los usa es main.lua (ritmo de aparicion y jefe) y
-- enemy.lua (vida y que tipos pueden aparecer).
Difficulty = {
    SPAWN_STEP = 0.07,         -- cuantos segundos baja el intervalo entre apariciones en cada nivel
    MIN_SPAWN_INTERVAL = 0.3,  -- el intervalo nunca baja de esto
    HP_STEP = 0.12,            -- cuanta vida extra tienen los enemigos en cada nivel (0.12 = +12%)
    BOSS_EVERY = 5,            -- llega un jefe en cada nivel multiplo de este numero
}

-- Nivel de dificultad actual. Hoy es el numero de ronda; si mas adelante se quitan las rondas
-- (como en Vampire Survivors), basta con que esta funcion devuelva otra cosa, por ejemplo los
-- minutos jugados, y todo lo demas sigue funcionando igual.
function Difficulty.level()
    return Round.number
end

-- Segundos entre un enemigo y el siguiente: parte de Config.SPAWN_INTERVAL en el nivel 1 y baja
function Difficulty.spawnInterval()
    local interval = Config.SPAWN_INTERVAL - Difficulty.SPAWN_STEP * (Difficulty.level() - 1)
    return math.max(Difficulty.MIN_SPAWN_INTERVAL, interval)
end

-- Multiplicador de la vida de los enemigos: 1 en el nivel 1 y sube en cada nivel
function Difficulty.hpMult()
    return 1 + Difficulty.HP_STEP * (Difficulty.level() - 1)
end

-- true si el nivel actual es de jefe (5, 10, 15...)
function Difficulty.isBossRound()
    return Difficulty.level() % Difficulty.BOSS_EVERY == 0
end
