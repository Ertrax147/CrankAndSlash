-- Definiciones de tipos de arma: solo valores, sin logica.
-- weapon.lua usa estos valores para crear armas nuevas (ver newWeapon en weapon.lua).
-- Para agregar un arma nueva, se agrega otra entrada aqui.
--   ORBIT_RADIUS: distancia del centro del dibujo al jugador
--   HITBOXES: la zona de dano, una lista de circulos { offset, radius }. "offset" es cuantos pixeles
--     hacia afuera del centro del dibujo esta el centro del circulo (negativo = hacia el jugador).
--     Un arma redonda (la maza) usa un solo circulo; una espada larga usa varios a lo largo de la
--     hoja, asi donde ves la hoja es donde pega.
--   DAMAGE: vida que le quita a un enemigo por golpe
--   BASE_SPEED / MAX_SPEED: grados por segundo que gira sin energia / con la energia al maximo
--   HIT_COOLDOWN: segundos que debe esperar antes de poder golpear de nuevo al mismo enemigo
--   SPRITE: dibujo del arma. ROTATE = true lo gira junto con la orbita, apuntando hacia afuera
--     (los dibujos miran hacia arriba). NO_CHAIN = true: sin cadena, sale directo del jugador.
WeaponTypes = {
    -- Maza con pinchos y cadena. Lista pero sin usar todavia: se podra conseguir mas adelante.
    MAZA = {
        ORBIT_RADIUS = 30,
        HITBOXES = { { offset = 0, radius = 6 } },
        DAMAGE = 1,
        BASE_SPEED = 120, MAX_SPEED = 540,
        HIT_COOLDOWN = 0.4,
        SPRITE = "images/weapon_maza",
    },

    -- Espada larga: el arma inicial. Gira directo desde el jugador; mas lenta que la maza, pero la
    -- hoja cubre mas area.
    ESPADA_LARGA = {
        ORBIT_RADIUS = 30,
        HITBOXES = { { offset = 15, radius = 5 }, { offset = 8, radius = 5 }, { offset = 1, radius = 5 } },
        DAMAGE = 1,
        BASE_SPEED = 100, MAX_SPEED = 450,
        HIT_COOLDOWN = 0.5,
        SPRITE = "images/weapon_espada_larga", ROTATE = true, NO_CHAIN = true,
    },

    -- Mandoble: grande y pesado. Pega el doble de fuerte, pero gira lento y tarda mas en volver a pegarle
    -- al mismo enemigo. Listo pero sin usar todavia: se podra conseguir mas adelante.
    MANDOBLE = {
        ORBIT_RADIUS = 34,
        HITBOXES = {
            { offset = 18, radius = 6 }, { offset = 10, radius = 6 },
            { offset = 2, radius = 6 }, { offset = -6, radius = 6 },
        },
        DAMAGE = 2,
        BASE_SPEED = 70, MAX_SPEED = 300,
        HIT_COOLDOWN = 0.7,
        SPRITE = "images/weapon_mandoble", ROTATE = true, NO_CHAIN = true,
    },
}
