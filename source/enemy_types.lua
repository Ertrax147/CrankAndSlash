-- Definiciones de los tipos de enemigo: solo valores, sin logica (igual que weapon_types.lua).
-- enemy.lua usa estos valores al crear cada enemigo. Para agregar un enemigo nuevo, se agrega
-- otra entrada aqui y se pone en EnemyTypes.LIST.
--   RADIUS: tamano para las colisiones (el dibujo puede ser mas grande o de otra forma)
--   SPEED: pixeles por segundo   HP: vida   DAMAGE: dano al tocar al jugador
--   MIN_ROUND: primera ronda en la que puede aparecer
--   WEIGHT: que tan seguido aparece comparado con los demas (mayor = mas frecuente)
--   SPRITE: nombre base de los dibujos (se agrega _1 y _2, los dos cuadros de la animacion)
--   ANIM_TIME: segundos que dura cada cuadro de la animacion
--   WOBBLE / WOBBLE_SPEED (opcionales): hacen que el enemigo avance en zigzag en vez de en linea recta.
--     WOBBLE es cuanto se desvia hacia los lados (0 = recto, 1 = mucho) y WOBBLE_SPEED que tan rapido cambia.
EnemyTypes = {
    FANTASMA = {
        RADIUS = 7, SPEED = 40, HP = 3, DAMAGE = 1, MIN_ROUND = 1, WEIGHT = 100,
        SPRITE = "images/enemy_fantasma", ANIM_TIME = 0.3,
    },
    -- Rapido y fragil: aletea muy seguido
    MURCIELAGO = {
        RADIUS = 6, SPEED = 70, HP = 2, DAMAGE = 1, MIN_ROUND = 2, WEIGHT = 50,
        SPRITE = "images/enemy_murcielago", ANIM_TIME = 0.12,
    },
    -- Rapida y erratica: avanza en zigzag
    ARANA = {
        RADIUS = 6, SPEED = 55, HP = 2, DAMAGE = 1, MIN_ROUND = 3, WEIGHT = 35,
        SPRITE = "images/enemy_arana", ANIM_TIME = 0.15,
        WOBBLE = 1.0, WOBBLE_SPEED = 5,
    },
    -- Tanque: lento, muy resistente y hace el doble de dano
    OSO = {
        RADIUS = 11, SPEED = 22, HP = 10, DAMAGE = 2, MIN_ROUND = 4, WEIGHT = 18,
        SPRITE = "images/enemy_oso", ANIM_TIME = 0.35,
    },
}

-- Lista de los tipos que pueden aparecer en el juego
EnemyTypes.LIST = {
    EnemyTypes.FANTASMA,
    EnemyTypes.MURCIELAGO,
    EnemyTypes.ARANA,
    EnemyTypes.OSO,
}
