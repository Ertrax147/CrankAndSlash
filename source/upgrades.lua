-- Mejoras que se pueden elegir al subir de nivel. Cada una tiene un nombre, una descripcion corta
-- y una funcion "apply" que modifica las estadisticas (Stats) o da algo nuevo (la pistola).
-- Opcionalmente tiene "available": si existe y devuelve false, esa mejora no se ofrece (por
-- ejemplo, la pistola no se ofrece si ya la tienes). El menu muestra CHOICES al azar.
Upgrades = {
    CHOICES = 3,          -- cuantas opciones se ofrecen cada vez
    HP_STEP = 1,          -- vida maxima que da "Vitalidad" (y cuanto cura)
    DAMAGE_STEP = 0.15,   -- +15% de dano
    SPEED_STEP = 0.08,    -- +8% de velocidad de movimiento
    ENERGY_STEP = 0.10,   -- +10% de energia por giro de manivela
    FIRE_RATE_STEP = 0.10 -- +10% de cadencia de la pistola
}

-- Convierte 0.15 en "15" para escribirlo en las descripciones
local function percent(step)
    return math.floor(step * 100 + 0.5)
end

Upgrades.LIST = {
    {
        name = "Vitalidad",
        text = "+" .. Upgrades.HP_STEP .. " vida maxima y te cura " .. Upgrades.HP_STEP,
        apply = function()
            Stats.hpBonus = Stats.hpBonus + Upgrades.HP_STEP
            Player.hp = math.min(Player.hp + Upgrades.HP_STEP, Stats.maxHp())
        end,
    },
    {
        name = "Fuerza",
        text = "+" .. percent(Upgrades.DAMAGE_STEP) .. "% de dano con el arma y la pistola",
        apply = function() Stats.damageMult = Stats.damageMult + Upgrades.DAMAGE_STEP end,
    },
    {
        name = "Rapidez",
        text = "+" .. percent(Upgrades.SPEED_STEP) .. "% de velocidad al moverte",
        apply = function() Stats.speedMult = Stats.speedMult + Upgrades.SPEED_STEP end,
    },
    {
        name = "Carga",
        text = "+" .. percent(Upgrades.ENERGY_STEP) .. "% de energia por giro de la manivela",
        apply = function() Stats.energyMult = Stats.energyMult + Upgrades.ENERGY_STEP end,
    },
    {
        name = "Pistola",
        text = "Arma nueva: dispara sola al enemigo mas cercano",
        apply = function() Ranged.unlocked = true end,
        available = function() return not Ranged.unlocked end, -- solo se ofrece una vez
    },
    {
        name = "Punteria",
        text = "+" .. percent(Upgrades.FIRE_RATE_STEP) .. "% de cadencia de la pistola",
        apply = function() Stats.fireRateMult = Stats.fireRateMult + Upgrades.FIRE_RATE_STEP end,
        available = function() return Ranged.unlocked end, -- de nada sirve sin la pistola
    },
}

-- Devuelve hasta CHOICES mejoras distintas elegidas al azar, entre las que estan disponibles
function Upgrades.pickChoices()
    local pool = {}
    for i = 1, #Upgrades.LIST do
        local upgrade = Upgrades.LIST[i]
        if not upgrade.available or upgrade.available() then
            pool[#pool + 1] = upgrade
        end
    end
    local choices = {}
    for i = 1, math.min(Upgrades.CHOICES, #pool) do
        local index = math.random(#pool)
        choices[i] = pool[index]
        table.remove(pool, index) -- ya salio: no se puede repetir en este menu
    end
    return choices
end
