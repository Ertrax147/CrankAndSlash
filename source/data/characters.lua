-- Definiciones de los personajes jugables: solo valores, sin logica (igual que enemy_types.lua).
-- player.lua dibuja al personaje elegido. Para agregar uno nuevo: sus dos dibujos en
-- source/images/player/ (nombre_1.png y nombre_2.png), una entrada aqui y ponerla en Characters.LIST.
--   NAME: nombre que se muestra al elegirlo
--   SPRITE: nombre base de los dibujos (se agrega _1 y _2, los dos cuadros de la caminata)
--   BOLTS: true si lo rodean rayos cuando hay energia
--   CRANK_PIVOT_X / CRANK_PIVOT_Y (opcionales): si estan, dibuja una manivela que gira con la energia,
--     y este es el punto del dibujo (en pixeles desde su esquina) donde queda su eje
--   WHEEL_X / WHEEL_Y (opcionales): centro de la caja, donde se dibuja el volante (la alternativa a la
--     manivela). Con el volante se usan los dibujos SPRITE .. "_volante" (la caja sin el rayo)
--   ANTENNA_X / ANTENNA_Y (opcionales): centro de la bola de la antena, de donde pueden salir los rayos
Characters = {
    GUERRERO = {
        NAME = "Guerrero", SPRITE = "images/player/guerrero", BOLTS = false,
    },
    CIENTIFICO_ARMADURA = {
        NAME = "Cient. armadura", SPRITE = "images/player/cientifico_armadura", BOLTS = true,
    },
    CIENTIFICO_SIMPLE = {
        NAME = "Cient. simple", SPRITE = "images/player/cientifico_simple", BOLTS = true,
    },
    CIENTIFICO = {
        NAME = "Cientifico 1", SPRITE = "images/player/cientifico", BOLTS = true,
        CRANK_PIVOT_X = 2, CRANK_PIVOT_Y = 19, ANTENNA_X = 6, ANTENNA_Y = 4,
        WHEEL_X = 6.5, WHEEL_Y = 19,
    },
    CIENTIFICO_REDONDO = {
        NAME = "Cientifico 2", SPRITE = "images/player/cientifico_redondo", BOLTS = true,
        CRANK_PIVOT_X = 2, CRANK_PIVOT_Y = 19, ANTENNA_X = 6, ANTENNA_Y = 4,
        WHEEL_X = 6.5, WHEEL_Y = 19,
    },
    CIENTIFICO_NUBE = {
        NAME = "Cientifico 3", SPRITE = "images/player/cientifico_nube", BOLTS = true,
        CRANK_PIVOT_X = 2, CRANK_PIVOT_Y = 19, ANTENNA_X = 6, ANTENNA_Y = 4,
        WHEEL_X = 6.5, WHEEL_Y = 19,
    },
    CIENTIFICO_PROFESOR = {
        NAME = "Profesor", SPRITE = "images/player/cientifico_profesor", BOLTS = true,
        CRANK_PIVOT_X = 2, CRANK_PIVOT_Y = 19, ANTENNA_X = 6, ANTENNA_Y = 4,
        WHEEL_X = 6.5, WHEEL_Y = 19,
    },
}

-- Orden en que se ofrecen al elegir
Characters.LIST = {
    Characters.CIENTIFICO, Characters.CIENTIFICO_REDONDO, Characters.CIENTIFICO_NUBE,
    Characters.CIENTIFICO_PROFESOR, Characters.CIENTIFICO_ARMADURA, Characters.CIENTIFICO_SIMPLE,
    Characters.GUERRERO,
}
