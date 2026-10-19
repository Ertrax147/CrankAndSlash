-- Pistola: dispara sola cada cierto tiempo hacia el enemigo mas cercano.
Ranged = {
    BASE_COOLDOWN = 1.2, -- segundos entre disparos sin energia
    MIN_COOLDOWN = 0.4,  -- segundos entre disparos con energia llena (antes 0.2, era demasiado fuerte)
}

-- La pistola empieza apagada: el jugador la consigue como una mejora al subir de nivel
-- (Upgrades), que enciende Ranged.unlocked.
function Ranged.reset()
    Ranged.cooldown = 0
    Ranged.unlocked = false
end

function Ranged.update(dt)
    if not Ranged.unlocked then return end

    Ranged.cooldown = Ranged.cooldown - dt
    if Ranged.cooldown > 0 then return end

    local target = Enemy.closest(Player.x, Player.y)
    if target then
        Projectile.spawn(Player.x, Player.y, target.x, target.y)
        -- igual que Weapon.update: mas energia, menos espera entre disparos
        Ranged.cooldown = (Ranged.BASE_COOLDOWN - (Ranged.BASE_COOLDOWN - Ranged.MIN_COOLDOWN) * Energy.ratio()) / Stats.fireRateMult
    end
end
