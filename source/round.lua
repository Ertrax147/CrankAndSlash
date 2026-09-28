-- Rondas: temporizador que cuenta hacia atras.
Round = {
    TIME_LIMIT = 30, -- segundos que dura cada ronda
    timeLeft = 30,
    number = 1,
}

function Round.reset()
    Round.number = 1
    Round.timeLeft = Round.TIME_LIMIT
end

function Round.update(dt)
    Round.timeLeft = Round.timeLeft - dt
    if Round.timeLeft <= 0 then
        Round.number = Round.number + 1
        Round.timeLeft = Round.TIME_LIMIT
    end
end
