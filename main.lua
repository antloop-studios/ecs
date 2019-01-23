-- SETUP --------------------------------------------------------------------------------

require "zip"
local e, c, s = unpack(require "ecs")

c.position = {x = 0, y = 0}
c.velocity = {x = 0, y = 0}

e.movable = {c.position, c.velocity}

s.physics = {c.position, c.velocity}
s.physics.update = function(position, velocity)
   local i = 0

   for position, velocity in zip(position, velocity) do
      i = i + 1

      if e[i] then
         position.x = position.x + velocity.x
         position.y = position.y + velocity.y

         if position.x > 600 or position.y > 400 then
            if math.random() < 0.4 then
               e.del(i)
            else
               position.x = 0
               position.y = 0
            end
         end
      end
   end
end

-- TEST ---------------------------------------------------------------------------------

function count(table)
   local i = 0
   for _ in pairs(table) do
      i = i + 1
   end
   return i - 1
end

local N = 50000

function time(name, n, call)
   print(name)
   local t = os.clock()
   call()
   print("all: " .. ((os.clock() - t) / n * 1000) .. "ms")
   print("one: " .. ((os.clock() - t) / n / N * 1000 * 1000) .. "us")
   print("")
end

time(
   "ALLOCATE",
   1,
   function()
      for _ = 1, N do
         e.movable({x = 10, y = 10}, {x = math.random(10, 30), y = math.random(10, 30)})
      end
   end
)

time(
   "DESTROY",
   1,
   function()
      for _ = 1, N do
         if e[_] then
            e.del(_)
         end
      end
   end
)

time(
   "REOCCUPY",
   1,
   function()
      for _ = 1, N do
         e.movable({x = 10, y = 10}, {x = math.random(10, 30), y = math.random(10, 30)})
      end
   end
)

time(
   "ITERATE",
   100,
   function()
      for i = 1, 100 do
         s()
      end
   end
)
print(
   getmetatable(e).__reserve ..
      " reserved " ..
         getmetatable(e).__used ..
            " used " ..
               getmetatable(e).__used - count(getmetatable(e).__free) .. " active"
)
print((collectgarbage("count") / 1024) .. "mb")
