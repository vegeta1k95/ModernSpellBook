-- ====================== OOP ===================================

function ClassCreate(name)
    
    if (_G[name] ~= nil) then
       error("Class " .. name .. " already exists!" )
       return
    end

    -- Class table - store methods
    local class = {}
    class.__index = class				 -- Objects are will be looking for missing fields here
	class.__classname = name			 -- Store class name
	class.__class = class				 -- Store class reference for objects
    class.__init = function(self) end    -- Class default (empty) constructor
	
    -- Class metatable
    local class_meta  = {
        
        -- Class invokation `Class(...)`
        -- is just a creation of a new object
        __call = function(class, ...)
            local object = setmetatable({}, class)
			object.__init(object, unpack(arg))	-- Invoke constructor
            return object
        end
    }
    
    -- Make visible in global scope
    _G[name] = setmetatable(class, class_meta)
    
    return class
end

function ClassAddSuper(class, superclass)
    -- Copy entries (references) of superclass to class
    for name, method in pairs(superclass) do
        if (class[name] == nil) then
            class[name] = method
        end
    end
end


function ClassDefinition(class)
   
    -- It is a table returned by invoking `class "Name"`
    local definer = {
        
        __AddSuper = function(self, name)
           
           local superclass = _G[name]
           
           if (superclass) then
               ClassAddSuper(class, superclass)
               return self
           end
           
          error("Base class " .. super_name .. " not found!")
            
        end,
        
        extends = function(self, superclasses)
            
            if (type(superclasses) == "string") then
                self:__AddSuper(superclasses)
            elseif (type(superclasses) == "table") then
                for i, name in pairs(superclasses) do
                   self:__AddSuper(name)
                end
            end
            
            return self
            
        end
    }
    
    local definer_meta = {
        
        -- When definer is called - arguments are methods
        -- that go inside of class:
        -- class "Name" 
        -- {
        --    method_1 = function(self, a) end;
        --    method_2 = function(self, b) end;
        --    ...
        -- }
        __call = function(self, definition)
            
            -- Copy methods to class
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

function enum(name)

    local tbl = {}
    
    setmetatable(tbl, {
        __call = function(self, definition)
            for key, value in pairs(definition) do
               tbl[key] = value
            end
        end
    })

    _G[name] = tbl

    return tbl
end


-- ========================== Class serialization =========================

function Serialize(source, destination)
     
    if (source.__classname) then
        destination.__serialclass = source.__classname
    end
    
	for key, value in pairs(source) do
		if (type(value) == "table") then	
		    if (destination[key] == nil) then
	            destination[key] = {}
	        end
			Serialize(value, destination[key])
		elseif (type(value) ~= "function") then
			destination[key] = value
		end
    end
end


function Deserialize(source, destination)
    
    if (source.__serialclass) then
        local meta = _G[source.__serialclass]
        setmetatable(destination, meta)
    end
    
    for key, value in pairs(source) do
		if (type(value) == "table") then	
		    if (destination[key] == nil) then
	            destination[key] = {}
	        end
			Deserialize(value, destination[key])
		elseif (type(value) ~= "function") then
			destination[key] = value
		end
	end
end


-- ========================== HELPER ======================================


function ChooseRandom(tbl)
	if (tbl) then
		return tbl[math.random(1, table.getn(tbl))]
	end
	return nil
end

-- Sorted iterator - iterate table base on provided sorting.
function spairs(t, order)

    -- Collect the keys
    local keys = {}
    for k in pairs(t) do 
		keys[table.getn(keys)+1] = k 
	end

    -- If order function given, sort by it by passing the table and keys a, b,
    -- otherwise just sort the keys
    if order then
        table.sort(keys, function(a,b) return order(t, a, b) end)
    else
        table.sort(keys)
    end

    -- Return the iterator function
    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end