--[[
   Author: Antloop
   Author: evolbug (Daniels Kursits)
   MIT License, 2019
--]]
---- MISC -------------------------------------------------------------------------------

-- build system cache keys
local function make_keys(components, c)
    local keys = {}
    for c = c or 1, #components do
        keys[#keys + 1] = components[c]
        for _, k in ipairs(make_keys(components, c + 1)) do
            keys[#keys + 1] = components[c] .. tostring(k)
        end
    end
    return keys
end

---- INIT -------------------------------------------------------------------------------

local entity = {}
local emeta = {__index = {}, free = {}, used = 0}
setmetatable(entity, emeta)

local component = {}
local cmeta = {__index = {}}
setmetatable(component, cmeta)

local system = {}
local smeta = {bykey = {}}
setmetatable(system, smeta)

--- ENTITY ------------------------------------------------------------------------------

-- delete an entity by id
-- e.delete(id)
function emeta.__index.delete(id)
    rawset(entity, id, nil)
    emeta.free[#emeta.free + 1] = id
    for syskey, data in pairs(smeta.bykey) do
        local sid = data.etos[id]
        if sid then
            data.etos[id] = nil
            data.free[sid] = true
            data[sid] = nil
        end
    end
end

-- get entity components by id
-- components = e.get(id)
function emeta.__index.get(id)
    local e = {}
    for i, c in pairs(component) do
        e[i] = cmeta.__index[i][id]
    end
    return e
end

function emeta.__index.len()
    return emeta.used
end

-- new entity type
-- e.name = components
function emeta:__newindex(name, components)
    -- create system keys if necessary
    table.sort(components)
    local syskeys = make_keys(components)

    for _, key in ipairs(syskeys) do
        if smeta.bykey[key] == nil then
            smeta.bykey[key] = {free = {}, etos = {}, used = 0}
        end
    end

    -- do not overwrite reserved names
    if emeta.__index[name] then
        error("entity: name <" .. name .. "> is reserved", 2)
    end

    setmetatable(
        components, {
            -- constructor
            -- e.name{init}
            __call = function(self, init)
                -- verify fields
                for c, _ in pairs(init) do
                    if type(_) ~= "table" then
                        error("entity: <" .. name .. "> component <" .. c .. "> must be a table", 2)
                    end
                    if component[c] == nil then
                        error("entity: <" .. name .. "> component <" .. c .. "> is not defined", 2)
                    end
                end
                for _, c in ipairs(self) do
                    if init[c] == nil then
                        error("entity: <" .. name .. "> requires component <" .. c .. ">", 2)
                    end
                    for f in pairs(component[c]) do
                        if init[c][f] == nil then
                            error(
                                "entity: <" .. name .. "> component <" .. c .. "> requires field <"
                                    .. f .. ">", 2
                            )
                        end
                    end
                end

                -- get free slot
                local id = emeta.free[#emeta.free]
                if id then
                    emeta.free[#emeta.free] = nil
                else
                    emeta.used = emeta.used + 1
                end
                id = id or emeta.used
                rawset(entity, id, true)

                -- initialize components
                for c = 1, #components do
                    cmeta.__index[components[c]][id] = init[components[c]]
                end

                -- cache entity id's in systems for better performance
                for _, key in ipairs(syskeys) do
                    local system = smeta.bykey[key]
                    local sid = system.free[#system.free] and #system.free or nil

                    if sid then
                        system.free[#system.free] = nil
                        --  sid = system.etos[id]
                    else
                        system.used = system.used + 1
                    end

                    system[sid or system.used] = id
                    system.etos[id] = sid or system.used
                end

                return id
            end,
        }
    )

    rawset(self, name, components)
end

-- COMPONENT ----------------------------------------------------------------------------

-- create a component type
-- c.name = fields
function cmeta:__newindex(name, fields)
    cmeta.__index[name] = {}

    if type(fields) ~= "table" then
        error("component: <" .. name .. "> must be a table", 2)
    end

    rawset(self, name, fields)
end

--- SYSTEM ------------------------------------------------------------------------------
-- update all or specified systems
-- s(...)
function smeta:__call(...)
    local systems = {...}
    systems = #systems > 0 and systems or self

    for _, system in pairs(systems) do
        system()
    end
end

function smeta:__newindex(name, components)
    -- create system key
    local syskey = {}
    for _, c in ipairs(components) do
        syskey[#syskey + 1] = c
    end
    table.sort(syskey)
    syskey = table.concat(syskey, "")
    if smeta.bykey[syskey] == nil then
        smeta.bykey[syskey] = {free = {}, used = 0}
    end

    -- verify component existence and build key
    local datakey = "return function(id) return id"
    for i = 1, #components do
        if component[components[i]] == nil then
            error("system: <" .. name .. "> component <" .. components[i] .. "> is not defined", 2)
        end

        datakey = datakey .. ", " .. components[i] .. "[id]"
    end
    datakey = setfenv(assert(loadstring(datakey .. " end"))(), cmeta.__index)

    rawset(
        self, name, setmetatable(
            {}, {
                -- create new subsystem
                -- s.system.name = subsystem
                __newindex = function(self, name, subsystem)
                    rawset(self, name, subsystem)
                    rawset(self, #self + 1, subsystem)
                end,
                -- update system
                -- s.system()
                __call = function(self)
                    local system = smeta.bykey[syskey]

                    for s = 1, #self do -- for each system
                        local subsys = self[s]

                        for e = 1, system.used do -- for each subsystem
                            local id = system[e] -- get real id

                            if id and system.free[id] == nil then -- if entity is active
                                subsys(datakey(id))
                            end
                        end
                    end
                end,
            }
        )
    )
end

return {entity, component, system}
