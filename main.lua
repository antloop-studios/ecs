-- SETUP --------------------------------------------------------------------------------

local e, c, s = unpack(require "ecs")

c.position = {x = 0, y = 0}
c.velocity = {x = 0, y = 0}
c.other = {testing = 10}

e.movable = {"position", "velocity"}
e.other = {"other"}

s.physics = {"position", "velocity"}
s.physics.update = function(i, position, velocity)
   position.x = position.x + velocity.x
   position.y = position.y + velocity.y

   if position.x > 600 or position.y > 400 then
      if math.random() < 0.4 then
         e.delete(i)
      else
         position.x = 0
         position.y = 0
      end
   end
end

s.other = {"other"}
s.other.update = function(i, other)
   other.testing = other.testing + 1
end

-- TEST ---------------------------------------------------------------------------------

function count(table)
   local i = 0
   for _ in pairs(table) do
      i = i + 1
   end
   return i
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
      math.randomseed(os.time())
      for _ = 1, N do
         e.movable {
            position = {x = 10, y = 10},
            velocity = {x = math.random(10, 30), y = math.random(10, 30)}
         }
      end
   end
)

time(
   "DESTROY",
   1,
   function()
      for i = 1, N do
         if e[i] then
            e.delete(i)
         end
      end
   end
)

time(
   "REOCCUPY",
   1,
   function()
      for _ = 1, N do
         e.movable {
            position = {x = 10, y = 10},
            velocity = {x = math.random(10, 30), y = math.random(10, 30)}
         }
      end
   end
)

time(
   "ITERATE PHYSICS",
   100,
   function()
      for i = 1, 100 do
         s(s.physics)
      end
   end
)
time(
   "ITERATE OTHER",
   100,
   function()
      for i = 1, 100 do
         s(s.other)
      end
   end
)

print(
   getmetatable(e).used ..
      " allocated " .. getmetatable(e).used - count(getmetatable(e).free) .. " active"
)
print((collectgarbage("count") / 1024) .. "mb")
