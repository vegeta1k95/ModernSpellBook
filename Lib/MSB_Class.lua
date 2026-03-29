-- MSB_Class: Minimal OOP framework for ModernSpellBook
-- Provides: class "Name" :extends("Base") { __init = ...; Method = ...; }

local function ClassCreate(name)
    if (_G[name] ~= nil) then
        error("Class " .. name .. " already exists!")
        return
    end

    local class = {}
    class.__index = class
    class.__classname = name
    class.__class = class
    class.__init = function(self) end

    local class_meta = {
        __call = function(class, ...)
            local object = setmetatable({}, class)
            object.__init(object, unpack(arg))
            return object
        end
    }

    _G[name] = setmetatable(class, class_meta)
    return class
end

local function ClassAddSuper(class, superclass)
    for name, method in pairs(superclass) do
        if (class[name] == nil) then
            class[name] = method
        end
    end
end

local function ClassDefinition(class)
    local definer = {
        extends = function(self, superclasses)
            if (type(superclasses) == "string") then
                local superclass = _G[superclasses]
                if (superclass) then
                    ClassAddSuper(class, superclass)
                else
                    error("Base class " .. superclasses .. " not found!")
                end
            elseif (type(superclasses) == "table") then
                for _, name in pairs(superclasses) do
                    local superclass = _G[name]
                    if (superclass) then
                        ClassAddSuper(class, superclass)
                    else
                        error("Base class " .. name .. " not found!")
                    end
                end
            end
            return self
        end
    }

    local definer_meta = {
        __call = function(self, definition)
            for name, method in pairs(definition) do
                class[name] = method
            end
        end
    }

    return setmetatable(definer, definer_meta)
end

function class(name)
    return ClassDefinition(ClassCreate(name))
end
