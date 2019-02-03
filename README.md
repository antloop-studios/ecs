# ecs

Minimalist Lua ECS

## global ecs store

```lua
local e, c, s = unpack(require "ecs")
```

## components contain data with defaults

```lua
c.position = {x = 0, y = 0}
c.velocity = {x = 0, y = 0}
```

## entities contain components

```lua
-- create type
e.movable = {"position", "velocity"}

-- create entity of type
id = e.movable {
   position = {x = 10, y = 10},
   velocity = {x = math.random(10, 30), y = math.random(10, 30)}
}
```

## systems act on components

```lua
-- create system requirements
s.physics = {"position", "velocity"}

-- create subsystem that updates component state
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
```

## update all or specific systems

```lua
s() -- update all
s(s.physics) -- update specific
```
