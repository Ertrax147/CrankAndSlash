-- Combate: revisa las colisiones y aplica el dano
Combat = {
    CONTACT_DAMAGE = 1, -- dano que hace un enemigo al tocar al jugador
}

function Combat.update()
    local items = Enemy.pool.items
    for i = 1, #items do
        local e = items[i]
        if e.active then
            -- arma vs enemigo (con tiempo minimo entre golpes al mismo enemigo)
            if e.hitTimer <= 0 and Collision.circles(Weapon.x, Weapon.y, Weapon.RADIUS, e.x, e.y, Enemy.RADIUS) then
                e.hp = e.hp - Weapon.DAMAGE
                e.hitTimer = Weapon.HIT_COOLDOWN
                if e.hp <= 0 then
                    Enemy.pool:release(e)
                end
            end
            -- enemigo vs jugador
            if e.active and Collision.circles(Player.x, Player.y, Player.RADIUS, e.x, e.y, Enemy.RADIUS) then
                Player.hurt(Combat.CONTACT_DAMAGE)
            end
        end
    end
end
