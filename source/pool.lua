-- Object Pool generico: crea todos los objetos al inicio y los reutiliza.
-- Nunca se crea ni se destruye nada mientras se juega.
Pool = {}
Pool.__index = Pool

function Pool.new(size, factory)
    local self = setmetatable({}, Pool)
    self.items = {}
    for i = 1, size do
        local obj = factory()
        obj.active = false
        self.items[i] = obj
    end
    return self
end

-- Devuelve un objeto libre (y lo marca activo), o nil si el pool esta lleno
function Pool:acquire()
    for i = 1, #self.items do
        local obj = self.items[i]
        if not obj.active then
            obj.active = true
            return obj
        end
    end
    return nil
end

function Pool:release(obj)
    obj.active = false
end

function Pool:releaseAll()
    for i = 1, #self.items do
        self.items[i].active = false
    end
end
