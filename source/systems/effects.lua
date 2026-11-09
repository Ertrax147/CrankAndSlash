-- Efectos de golpe (opcionales: se encienden con Effects.enabled desde la pantalla de pruebas):
--   - un "puf" de particulas donde muere un enemigo
--   - un temblor de pantalla cuando el jugador recibe dano
--   - el destello de un enemigo al recibir un golpe (se dibuja en enemy.lua, con Effects.HIT_FLASH_TIME)
-- Las particulas usan un pool, como los proyectiles. La forma de cada puf sale de numeros fijos
-- (noise) y no de math.random, para no alterar el azar del resto del juego.
local gfx = playdate.graphics

Effects = {
    PARTICLES = 40,       -- cuantas particulas puede haber a la vez
    PUFF_COUNT = 6,       -- particulas por puf
    PUFF_LIFE = 0.3,      -- cuanto dura cada particula (segundos)
    PUFF_SPEED = 60,      -- velocidad con que salen (pixeles por segundo)
    SHAKE_TIME = 0.25,    -- cuanto dura el temblor de pantalla
    SHAKE_AMOUNT = 3,     -- cuanto se mueve la pantalla al principio (pixeles)
    HIT_FLASH_TIME = 0.08, -- cuanto dura el destello de un enemigo golpeado
}

Effects.startEnabled = false -- true: los efectos empiezan encendidos (la pantalla de pruebas lo puede cambiar)

local particles = Pool.new(Effects.PARTICLES, function()
    return { x = 0, y = 0, vx = 0, vy = 0, life = 0 }
end)
local counter = 0 -- da forma distinta a cada puf y a cada temblor

function Effects.reset()
    Effects.enabled = Effects.startEnabled
    Effects.shakeTimer = 0
    particles:releaseAll()
    Camera.shakeX = 0
    Camera.shakeY = 0
end

-- Numero entre 0 y 1 que depende solo de a, b y c (igual que en player.lua)
local function noise(a, b, c)
    local v = math.sin(a * 12.9898 + b * 78.233 + c * 37.719) * 43758.5453
    return v - math.floor(v)
end

-- Un puf de particulas que salen en todas direcciones desde (x, y)
function Effects.puff(x, y)
    if not Effects.enabled then return end
    counter = counter + 1
    for i = 1, Effects.PUFF_COUNT do
        local p = particles:acquire()
        if not p then return end -- sin particulas libres: no sale mas por ahora
        local angle = (i / Effects.PUFF_COUNT) * 2 * math.pi + noise(counter, i, 1) * 0.8
        local speed = Effects.PUFF_SPEED * (0.6 + noise(counter, i, 2) * 0.8)
        p.x, p.y = x, y
        p.vx, p.vy = math.cos(angle) * speed, math.sin(angle) * speed
        p.life = Effects.PUFF_LIFE
    end
end

-- Empieza un temblor de pantalla (lo llama Player.hurt)
function Effects.shake()
    if Effects.enabled then Effects.shakeTimer = Effects.SHAKE_TIME end
end

-- Mueve las particulas y calcula cuanto tiembla la pantalla (la camara suma Camera.shakeX/Y)
function Effects.update(dt)
    local items = particles.items
    for i = 1, #items do
        local p = items[i]
        if p.active then
            p.x = p.x + p.vx * dt
            p.y = p.y + p.vy * dt
            p.life = p.life - dt
            if p.life <= 0 then particles:release(p) end
        end
    end
    if Effects.shakeTimer > 0 then
        Effects.shakeTimer = Effects.shakeTimer - dt
        counter = counter + 1
        local amount = Effects.SHAKE_AMOUNT * math.max(0, Effects.shakeTimer) / Effects.SHAKE_TIME
        Camera.shakeX = (noise(counter, 3, 3) - 0.5) * 2 * amount
        Camera.shakeY = (noise(counter, 4, 4) - 0.5) * 2 * amount
    else
        Camera.shakeX = 0
        Camera.shakeY = 0
    end
end

-- Dibuja las particulas: bolitas negras con borde blanco que se achican hasta desaparecer
function Effects.draw()
    local items = particles.items
    for i = 1, #items do
        local p = items[i]
        if p.active then
            local x, y = Camera.toScreen(p.x, p.y)
            local radius = 1 + 2 * (p.life / Effects.PUFF_LIFE)
            gfx.setColor(gfx.kColorWhite)
            gfx.fillCircleAtPoint(x, y, radius + 1)
            gfx.setColor(gfx.kColorBlack)
            gfx.fillCircleAtPoint(x, y, radius)
        end
    end
end
