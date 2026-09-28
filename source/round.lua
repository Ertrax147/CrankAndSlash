-- Rondas: temporizador que cuenta hacia atras.
Round = {
    TIME_LIMIT = 30, -- segundos que dura cada ronda
    timeLeft = 30,
}

function Round.reset()
    Round.timeLeft = Round.TIME_LIMIT
end

function Round.update(dt)
    Round.timeLeft = Round.timeLeft - dt
    if Round.timeLeft < 0 then Round.timeLeft = 0 end
end
