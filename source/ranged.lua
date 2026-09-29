-- Pistola: dispara sola cada cierto tiempo hacia el enemigo mas cercano.
Ranged = {
    COOLDOWN = 1.0, -- segundos entre disparos
}

function Ranged.reset()
    Ranged.cooldown = 0
end

function Ranged.update(dt)
    Ranged.cooldown = Ranged.cooldown - dt
    if Ranged.cooldown > 0 then return end

    local target = Enemy.closest(Player.x, Player.y)
    if target then
        Projectile.spawn(Player.x, Player.y, target.x, target.y)
        Ranged.cooldown = Ranged.COOLDOWN
    end
end
