# ecs
Minimalist Lua ECS

## global ecs store
```lua
e, c, s = require 'ecs'
```

## components contain data with defaults
```lua
c.onec = {0, 0}
c.twoc = {x=10, x=10}
```

## entities contain components
```lua
-- create type
e.myentity = {c.onec, c.twoc}

-- create entity of type
id = e.myentity({1,2}, {y=20})
```

## systems act on components
```lua
-- create system requirements
s.mysys = {c.onec, c.twoc}

-- create subsystem that updates component state
s.mysys.update = function(onec, twoc)
   -- convenient zipper is provided for easier parallel array iteration
   for onec, twoc in zip(onec, twoc) do
      onec[0] = onec[0] + twoc.x
      twoc.y = onec[1] + twoc.y
   end
end

-- multiple subsystems can be added to a system
s.mysys.debug = function(onec, twoc)
   -- plain forloop can be used in place of zipper
   -- there might also be a slight performance benefit
   
   print('this is a debug subsystem')
   
   for i = 1, #onec do
      -- check if entity is live
      if e[i] then
         print('onec:', onec[i][0], onec[i][1])
         print('twoc:', 'x:'..twoc[i].x, 'y:'..twoc[i].y)
      end
   end
end
```

## update all or specific systems
```lua
s() -- update all
s(s.mysys, ...) -- update specific
```
