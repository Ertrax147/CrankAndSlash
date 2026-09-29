-- Combate: revisa las colisiones y aplica el dano
Combat = {
    CONTACT_DAMAGE = 1, -- dano que hace un enemigo al tocar al jugador
}

function Combat.update()
    local items = Enemy.pool.items
    for i = 1, #items do
        local e = items[i]
        if e.active then
            -- armas vs enemigo: recorre todas las armas del jugador (Weapon.list)
            -- y revisa si alguna esta tocando a este enemigo.
            -- e.hitTimer evita que un arma le pegue todos los frames mientras lo toca:
            -- despues de un golpe, el enemigo queda "inmune" por HIT_COOLDOWN segundos.
            if e.hitTimer <= 0 then
                for j = 1, #Weapon.list do
                    local w = Weapon.list[j]
                    if Collision.circles(w.x, w.y, w.def.RADIUS, e.x, e.y, Enemy.RADIUS) then
                        e.hp = e.hp - w.def.DAMAGE
                        e.hitTimer = w.def.HIT_COOLDOWN
                        if e.hp <= 0 then
                            Enemy.pool:release(e) -- vida en 0: el enemigo vuelve al pool
                        end
                        break -- ya se encontro un golpe este frame, no revisar mas armas
                    end
                end
            end
            -- proyectiles vs enemigo: un proyectil hace dano y desaparece al primer golpe
            if e.active then
                local projectiles = Projectile.pool.items
                for j = 1, #projectiles do
                    local p = projectiles[j]
                    if p.active and Collision.circles(p.x, p.y, Projectile.RADIUS, e.x, e.y, Enemy.RADIUS) then
                        e.hp = e.hp - Projectile.DAMAGE
                        Projectile.pool:release(p)
                        if e.hp <= 0 then
                            Enemy.pool:release(e)
                        end
                        break
                    end
                end
            end
            -- enemigo vs jugador: si un enemigo toca al jugador, le hace dano de contacto
            if e.active and Collision.circles(Player.x, Player.y, Player.RADIUS, e.x, e.y, Enemy.RADIUS) then
                Player.hurt(Combat.CONTACT_DAMAGE)
            end
        end
    end
end
