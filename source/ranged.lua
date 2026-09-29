-- Pistola: dispara sola cada cierto tiempo hacia el enemigo mas cercano.
Ranged = {
    BASE_COOLDOWN = 1.0, -- segundos entre disparos sin energia
    MIN_COOLDOWN = 0.2,  -- segundos entre disparos con energia llena
    UNLOCK_ROUND = 2,    -- ronda en la que se desbloquea la pistola
}

function Ranged.reset()
    Ranged.cooldown = 0
end

function Ranged.update(dt)
    if Round.number < Ranged.UNLOCK_ROUND then return end

    Ranged.cooldown = Ranged.cooldown - dt
    if Ranged.cooldown > 0 then return end

    local target = Enemy.closest(Player.x, Player.y)
    if target then
        Projectile.spawn(Player.x, Player.y, target.x, target.y)
        -- igual que Weapon.update: mas energia, menos espera entre disparos
        Ranged.cooldown = Ranged.BASE_COOLDOWN - (Ranged.BASE_COOLDOWN - Ranged.MIN_COOLDOWN) * Energy.ratio()
    end
end
