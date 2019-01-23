--[[
   Author: Antloop
   Author: evolbug
   MIT License, 2019
--]]
---- MISC -------------------------------------------------------------------------------
-- zip 2 iterables together, used for easier component iteration
-- c1, c2, c3 in zip(c1, zip(c2, zip(c3)))
-- c1, c2 in zip(c1, c2)
function zip(a, b)
   local i = 0
   if type(b) == "function" then
      return function()
         i = i + 1
         return a[i], b()
      end
   else
      return function()
         i = i + 1
         return a[i], b[i]
      end
   end
end

-- create or extend an array with <count> items with <fields>
local function allocate(count, fields, existing)
   local t = existing or {}
   for i = #t + 1, count do
      t[i] = {}
      for k, v in pairs(fields) do
         t[i][k] = v
      end
   end
   return t
end

---- INIT -------------------------------------------------------------------------------

local entity = {}
local component = {}
local system = {}

--- ENTITY ------------------------------------------------------------------------------

local emeta = {
   __reserve = 1,
   __used = 0,
   __free = {}
}
setmetatable(entity, emeta)

-- delete entity
-- e:del(index)
function entity.del(index)
   emeta.__free[index] = true
end

-- check if entity id exists
function emeta:__index(index)
   return not emeta.__free[index] and index <= emeta.__used and index > 0
end

-- return free entity id
function emeta:__call()
   if next(emeta.__free) then
      local slot = next(emeta.__free)
      emeta.__free[slot] = false

      return slot
   elseif emeta.__used >= emeta.__reserve then
      emeta.__reserve = emeta.__reserve * 2

      for name, c in pairs(component) do
         if name == "string" then
            allocate(emeta.__reserve, component[name], component[component[name]])
         end
      end
   end

   emeta.__used = emeta.__used + 1
   return emeta.__used
end

-- create new entity type
-- e.name = {components}
function emeta:__newindex(name, components)
   rawset(
      self,
      name,
      setmetatable(
         components,
         {
            __call = function(self, ...)
               local data = {...}
               local slot = entity()
               for c = 1, #data do
                  component[components[c]][slot] = data[c]
               end
            end
         }
      )
   )
end

-- COMPONENT ----------------------------------------------------------------------------

local cmeta = {}
setmetatable(component, cmeta)

-- create component
-- c.name = {fields}
function cmeta:__newindex(name, fields)
   rawset(self, name, fields)
   rawset(self, fields, allocate(emeta.__reserve, fields))
end

--- SYSTEM ------------------------------------------------------------------------------

local smeta = {}
setmetatable(system, smeta)

-- update all or specified systems
-- s(...)
function smeta:__call(...)
   local systems = {...}
   systems = #systems > 0 and systems or self
   for _, system in pairs(systems) do
      system()
   end
end

-- create new system
-- s.name = {key}
function smeta:__newindex(name, key)
   -- cache direct component array access
   local component_arrays = {}
   for c = 1, #key do
      component_arrays[c] = component[key[c]]
   end

   rawset(
      self,
      name,
      setmetatable(
         {},
         {
            __index = key,
            -- update subsystem
            -- s.name()
            __call = function(self)
               for name, subsystem in pairs(self) do
                  subsystem(unpack(component_arrays))
               end
            end
         }
      )
   )
end

return {entity, component, system}
