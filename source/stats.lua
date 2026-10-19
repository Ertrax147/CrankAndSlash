-- Mejoras del jugador: guarda cuanto se han mejorado sus estadisticas (al subir de nivel).
-- Los valores base siguen en cada modulo (Player.MAX_HP, Player.SPEED, etc.); aqui solo estan
-- los modificadores, y cada modulo los aplica al usar su valor base.
Stats = {}

function Stats.reset()
    Stats.hpBonus = 0       -- vida maxima extra (se suma a Player.MAX_HP)
    Stats.speedMult = 1     -- multiplica la velocidad de movimiento
    Stats.damageMult = 1    -- multiplica el dano del arma y de la pistola
    Stats.energyMult = 1    -- multiplica la energia que da cada giro de la manivela
    Stats.fireRateMult = 1  -- multiplica la cadencia de disparo de la pistola
    Stats.pickupBonus = 0   -- pixeles extra de alcance para recoger gemas
    Stats.reachMult = 1     -- multiplica la distancia a la que gira el arma del jugador
end

-- Vida maxima actual del jugador
function Stats.maxHp()
    return Player.MAX_HP + Stats.hpBonus
end
