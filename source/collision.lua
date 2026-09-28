-- Colisiones matematicas (sin motor de fisica)
Collision = {}

-- Dos circulos se tocan si la distancia entre centros <= suma de radios.
-- Se compara al cuadrado para evitar la raiz cuadrada.
function Collision.circles(ax, ay, ar, bx, by, br)
    local dx = ax - bx
    local dy = ay - by
    local r = ar + br
    return dx * dx + dy * dy <= r * r
end

-- Rectangulos alineados a los ejes (AABB). Se usara para elementos de la arena.
function Collision.aabb(ax, ay, aw, ah, bx, by, bw, bh)
    return ax < bx + bw and ax + aw > bx and ay < by + bh and ay + ah > by
end
