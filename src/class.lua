-- Simple OOP base class (prototype chain)
local Class = {}
Class.__index = Class

function Class:extend()
    local cls = {}
    for k, v in pairs(self) do cls[k] = v end
    cls.__index = cls
    cls.super = self
    function cls:new(...)
        local instance = setmetatable({}, cls)
        if instance.init then instance:init(...) end
        return instance
    end
    return cls
end

return Class