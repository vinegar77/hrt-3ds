local mapname,numHorses=...
require("love.math");require("love.audio");require("love.sound")
local HC = require("HC")
HC.resetHash(mapname=="map3" and 45 or 50)
local map = require("maps")(mapname,HC)
--unload maps file cache
package.loaded["maps"]=nil
--set local sqrt to avoid repeatedly calling math.
local sqrt=math.sqrt
local randNorm = love.math.randomNormal
local rand = love.math.random
local col = HC.collisions
local play = love.audio.play
--load audio
local hitSound={}
for i=1,3 do
    hitSound[i] = love.audio.newSource("resources/sounds/hit"..i..".wav","static")
end
--set 3 threads
local inHorChan=love.thread.getChannel("inHorses")
local outHorChan=love.thread.getChannel("outHorses")
local controlChan=love.thread.getChannel("control")
-- initialize the 3 horse arrays: 
--inHorses: inputs to collision module, give position and if sound should play
--shapeHorses: local HC shapes used to determine collisions
--outHorses: outputs from collision, send position and if sound played
local inHorses={}
for i=1,numHorses do
    inHorses[i]={map.horsePos[2*i-1],map.horsePos[2*i],.2}
end
local shapeHorses={}
for i=1,numHorses do
    shapeHorses[i]=HC.circle(inHorses[i][1],inHorses[i][2],9)
    shapeHorses[i].index=i
end
local outHorses={}
local function setDirection(i,ndx,ndy)
    local mag=sqrt(ndx^2+ndy^2)
    outHorses[i][1]=ndx/mag
    outHorses[i][2]=ndy/mag
end
for i=1,numHorses do
    outHorses[i]={nil,nil,false}
    setDirection(i,1,2*love.math.random()-1)
end
-- if ur reading this it's gb for girl boner (hardon collider)
--dt = 2/fps, starting with estimate, gets updated later
local dt,hspeed = 2/50,70
outHorChan:push(outHorses)
controlChan:demand()


while not controlChan:pop() do
    for h,_ in pairs(col(map.goal)) do
        controlChan:push(h.index)
        controlChan:push(h.index)
        controlChan:push(h.index)
        controlChan:push(h.index)
        outHorChan:push(false)
        break
    end
    for i,h in ipairs(shapeHorses) do
        local v=outHorses[i]
        for _, delta in pairs(col(h)) do
            ---[[
            if inHorses[i][3]<0 then
                outHorses[i][3]=true
                play(hitSound[rand(1,3)])
                inHorses[i][3]=.2
            end
            --]]
            --to stay true to the original adding a random element to collisions
            setDirection(i,delta.x+delta.y*randNorm()+v[1], delta.y+delta.x*randNorm()+v[2])
        end
    end
    outHorChan:push(outHorses)
    if controlChan:pop() then break end
    inHorses,dt,hspeed=unpack(inHorChan:demand())
    if not inHorses then break end
    for i,v in ipairs(outHorses) do
        if v[3] then
            inHorses[i][3]=.2
        end
    end
    for i,h in ipairs(shapeHorses) do
        local p=inHorses[i]
        h:moveTo(p[1],p[2])
        --estimate future horses
        local v=outHorses[i]
        v[3]=false
        h:move(v[1]*dt*hspeed,v[2]*dt*hspeed)
    end
end