-- Definiciones de tipos de arma: solo valores, sin logica.
-- weapon.lua usa estos valores para crear armas nuevas (ver newWeapon en weapon.lua).
-- Para agregar un arma nueva, se agrega otra entrada aqui (ej: WeaponTypes.RANGED = {...}).
WeaponTypes = {
    -- Arma cuerpo a cuerpo: gira sola alrededor del personaje en un circulo (orbita).
    MELEE = {
        ORBIT_RADIUS = 30, -- distancia del arma al personaje mientras gira
        RADIUS = 6,        -- tamano del arma, se usa para saber si toco a un enemigo
        DAMAGE = 1,        -- vida que le quita a un enemigo por golpe
        BASE_SPEED = 120,   -- grados por segundo que gira sin energia de la manivela
        MAX_SPEED = 540,    -- grados por segundo que gira con la energia al maximo
        HIT_COOLDOWN = 0.4, -- segundos que debe esperar antes de poder golpear de nuevo al mismo enemigo
    },
}
