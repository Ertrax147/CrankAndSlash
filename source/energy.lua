-- Energia de la manivela: girar la carga, con el tiempo se descarga sola.
Energy = {
    value = 0,
    MAX = 100,
    CHARGE_PER_DEGREE = 0.12, -- cuanta energia da cada grado girado
    DECAY_PER_SECOND = 12,    -- cuanta energia se pierde por segundo
}

function Energy.reset()
    Energy.value = 0
end

function Energy.update(dt)
    local change = playdate.getCrankChange() -- grados girados desde el frame anterior
    Energy.value = Energy.value + math.abs(change) * Energy.CHARGE_PER_DEGREE
    Energy.value = Energy.value - Energy.DECAY_PER_SECOND * dt
    if Energy.value < 0 then Energy.value = 0 end
    if Energy.value > Energy.MAX then Energy.value = Energy.MAX end
end

-- Devuelve un numero entre 0 (sin energia) y 1 (energia llena)
function Energy.ratio()
    return Energy.value / Energy.MAX
end
