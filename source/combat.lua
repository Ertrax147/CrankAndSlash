-- Combate: revisa las colisiones y aplica el dano
-- El tamano (RADIUS) y el dano por contacto (DAMAGE) de cada enemigo vienen de su tipo: e.def
Combat = {}

-- Se llama cuando un enemigo se queda sin vida: suelta gemas donde murio y vuelve al pool.
-- Los enemigos normales sueltan 1; el jefe suelta varias (def.GEMS), repartidas alrededor.
local function killEnemy(e)
    local count = e.def.GEMS or 1
    for i = 1, count do
        if count == 1 then
            Gems.spawn(e.x, e.y)
        else
            Gems.spawn(e.x + math.random(-24, 24), e.y + math.random(-24, 24))
        end
    end
    Enemy.pool:release(e)
end

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
                    if Collision.circles(w.x, w.y, w.def.RADIUS, e.x, e.y, e.def.RADIUS) then
                        e.hp = e.hp - w.def.DAMAGE * Stats.damageMult
                        e.hitTimer = w.def.HIT_COOLDOWN
                        if e.hp <= 0 then
                            killEnemy(e)
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
                    if p.active and Collision.circles(p.x, p.y, Projectile.RADIUS, e.x, e.y, e.def.RADIUS) then
                        e.hp = e.hp - Projectile.DAMAGE * Stats.damageMult
                        Projectile.pool:release(p)
                        if e.hp <= 0 then
                            killEnemy(e)
                        end
                        break
                    end
                end
            end
            -- enemigo vs jugador: si un enemigo toca al jugador, le hace dano de contacto
            if e.active and Collision.circles(Player.x, Player.y, Player.RADIUS, e.x, e.y, e.def.RADIUS) then
                Player.hurt(e.def.DAMAGE)
            end
        end
    end
end
