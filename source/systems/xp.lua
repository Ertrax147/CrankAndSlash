-- Experiencia y nivel del jugador: se gana recogiendo gemas. Al llenar la barra se sube de nivel.
Xp = {
    BASE_NEEDED = 4,      -- experiencia para pasar del nivel 1 al 2
    NEEDED_PER_LEVEL = 2, -- cuanta experiencia mas pide cada nivel siguiente
}

function Xp.reset()
    Xp.level = 1
    Xp.current = 0 -- experiencia acumulada dentro del nivel actual
end

-- Experiencia que hace falta para completar el nivel actual
function Xp.needed()
    return Xp.BASE_NEEDED + (Xp.level - 1) * Xp.NEEDED_PER_LEVEL
end

-- Devuelve un numero entre 0 (barra vacia) y 1 (a punto de subir de nivel)
function Xp.ratio()
    return Xp.current / Xp.needed()
end

-- Suma experiencia (la llaman las gemas al ser recogidas). Si se llena la barra sube de nivel,
-- y la experiencia que sobra pasa al nivel siguiente (un ciclo por si una sola suma sube varios).
function Xp.add(amount)
    Xp.current = Xp.current + amount
    while Xp.current >= Xp.needed() do
        Xp.current = Xp.current - Xp.needed()
        Xp.level = Xp.level + 1
    end
end
