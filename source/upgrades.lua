-- Mejoras que se pueden elegir al subir de nivel. Cada una tiene un nombre, una descripcion corta
-- y una funcion "apply" que modifica las estadisticas (Stats). El menu muestra CHOICES al azar.
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
        name = "Punteria",
        text = "+" .. percent(Upgrades.FIRE_RATE_STEP) .. "% de cadencia de la pistola",
        apply = function() Stats.fireRateMult = Stats.fireRateMult + Upgrades.FIRE_RATE_STEP end,
    },
}

-- Devuelve CHOICES mejoras distintas elegidas al azar
function Upgrades.pickChoices()
    local pool = {}
    for i = 1, #Upgrades.LIST do
        pool[i] = Upgrades.LIST[i]
    end
    local choices = {}
    for i = 1, Upgrades.CHOICES do
        local index = math.random(#pool)
        choices[i] = pool[index]
        table.remove(pool, index) -- ya salio: no se puede repetir en este menu
    end
    return choices
end
