-- Rondas: temporizador que cuenta hacia atras.
Round = {
    TIME_LIMIT = 30, -- segundos que dura cada ronda
    timeLeft = 30,
    number = 1,
    startNumber = 1, -- ronda con la que empieza cada partida (la pantalla de pruebas la puede cambiar)
}

function Round.reset()
    Round.number = Round.startNumber
    Round.timeLeft = Round.TIME_LIMIT
end

-- Devuelve true el frame en que empieza una ronda nueva
function Round.update(dt)
    Round.timeLeft = Round.timeLeft - dt
    if Round.timeLeft <= 0 then
        Round.number = Round.number + 1
        Round.timeLeft = Round.TIME_LIMIT
        return true
    end
    return false
end
