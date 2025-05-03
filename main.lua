---[[
    require"nest".init({console="3ds",scale=2})
if arg[2] == "debug" then
    require("lldebugger").start()
end
--]]


--using HC collisions module
HC = require 'HC'
local Maps = require "maps"

-- initialize a few local variables
local map,winscreen={},{}
-- will adjust this when adding customizable horse lineups, for now just at start
local currentHorses={"Jovial Merryment","Cyan","Superstitional Realism","Yellow","Bullet'n Board","Door Knob","Comely Material Morning",
    "Downtown Skybox","Resolute Mind Afternoon"}
-- making these local to file:
local horses,flags,tFont,hspeed,cTime,pybStageTimer,wonTime,mapname,trial,hitSound,betSound,pybbox,xgc,ygc,numHorses,frames,gate,raceMus

-- function for the horses to set their direction
local function setDirection(self,ndx,ndy)
    local mag=math.sqrt(ndx^2+ndy^2)
    self.dx=ndx/mag
    self.dy=ndy/mag
end

--creates a horse which is a HC circle object with a name icon and some other properties
local function newHorse(x,y,r,name,icon,dx,dy)
    local h=HC.circle(x,y,r)
    local i=love.graphics.newImage("resources/horses/"..icon)
    h.name,h.icon,h.soundBuffer = name,i,0
    h.setDirection=setDirection
    h:setDirection(dx,dy)
    table.insert(horses,h)
    return h
end

--moves horses and accounts for collisions
local function moveHorses(dt)
    for _,v in ipairs(horses) do
        v:move(v.dx*hspeed*dt,v.dy*hspeed*dt)
        -- soundBuffer to prevent horses from making multiple hit sounds when hitting a wall once
        v.soundBuffer=v.soundBuffer-dt
    end
    -- check for collisions on horse every other frame
    if math.fmod(frames,2)==1 then
        return
    end
    for _,v in ipairs(horses) do
        for _, delta in pairs(HC.collisions(v)) do
            ---[[
            if v.soundBuffer<0 then
                local i = love.math.random(1,3)
                hitSound[i]:play()
                v.soundBuffer=.2
            end
            --]]
            --to stay true to the original adding a random element to collisions
            v:setDirection(delta.x+delta.y*love.math.randomNormal(1,0)+v.dx, delta.y+delta.x*love.math.randomNormal(1,0)+v.dy)
        end
    end
end

local function movePYB(dt)
    --move the place ur bets box
    pybbox.x=pybbox.x+pybbox.dx*dt*pybbox.speed
    pybbox.y=pybbox.y+pybbox.dy*dt*pybbox.speed
    pybbox.dx=(pybbox.x>235 or pybbox.x<40) and -pybbox.dx or pybbox.dx
    pybbox.dy=(pybbox.y>210 or pybbox.y<0) and -pybbox.dy or pybbox.dy
end

local function PYB(dt)
    -- updates the place your bets box
    if not flags.bets then
        pybStageTimer=cTime+1
        betSound:play()
        flags.bets=true
    end
    movePYB(dt)
    if cTime-pybStageTimer>1.1 then
        pybStageTimer=cTime
        pybbox.stage=pybbox.stage-1
        if pybbox.stage==-1 then
            flags.start=false
            --betSound:stop()
            raceMus:play()
            for _,v in ipairs(pybbox.allIcons) do
                v:release()
            end
            return
        end
        pybbox.icon=pybbox.allIcons[pybbox.stage]
    end
end

local function checkWin()
    -- checks if collision with goal
    for h,_ in pairs(HC.collisions(map.goal)) do
        flags.won=true
        hspeed=0
        love.audio.stop()
        local winsound=love.audio.newSource("resources/sounds/victory1.mp3","stream")
        winsound:play()
        local winImg=love.graphics.newImage("resources/winscreens/win"..string.sub(h.name,0,3)..".png")
        local winTxt=love.graphics.newImage("resources/winscreens/txt"..string.sub(h.name,0,3)..".png")
        local longNames={Res=.76,Com=.96}
        local winTxt2,s
        if longNames[string.sub(h.name,0,3)] then
            winTxt2=love.graphics.newImage("resources/winscreens/txt"..string.sub(h.name,0,3).."2.png")
            s=longNames[string.sub(h.name,0,3)]
        end
        return winImg,winTxt,{txt=winTxt2,scale=s}
    end
    return nil,nil,nil
end

-- function to restart everything or initialize for first time 
local function startTest()
    -- reset HC
    HC.resetHash(50)
    -- reset background color
    love.graphics.setBackgroundColor(0,.4,0)
    -- reset flags + timers + horse array
    flags={start=true,won=false}
    pybStageTimer,wonTime,cTime=0,0,0
    horses={}
    -- reset sounds
    love.audio.stop()
    -- choose map (move later maybe)
    mapname="map1"
    -- initialize collision map
    map=Maps.initMap(mapname)
    xgc,ygc=map.goal:center()
    -- shuffle horse list
    for i = #currentHorses, 2, -1 do
        local j = love.math.random(i)
        currentHorses[i], currentHorses[j] = currentHorses[j], currentHorses[i]
      end
    -- add horses to the scene
    for i,h in ipairs(currentHorses) do
        if i>numHorses then break end
        local sname= string.sub(h,0,3)
        newHorse(map.horsePos[2*i-1],map.horsePos[2*i],(sname=="Jov" and 10 or 9),h,sname..".png",1,love.math.random(-1,1))
    end
    -- initial horse speed
    hspeed=0
    -- set gate sprite
    gate=love.graphics.newImage("resources/pyb/gate.png")
    -- set up pyb box
    pybbox={x=40,y=210,dx=1,dy=-1,speed=30,stage=10,allIcons={}}
    for i=0,10 do
        pybbox.allIcons[i]=love.graphics.newImage("resources/pyb/pyb"..i..".png")
    end
    pybbox.icon=pybbox.allIcons[10]
    -- set trial number
    trial= (trial or 0)+1
    love.hrt = "e3DSm"..mapname:sub(-1).."t"..trial
end

function love.gamepadpressed(_,button)
    if button=="start" then
        love.event.quit()
    return end
    if button=="back" then
        startTest()
    return end
    if button=="dpup" then
        numHorses=numHorses<9 and numHorses+1 or 9
    return end
    if button=="dpdown" then
        numHorses=numHorses>1 and numHorses-1 or 1
    return end
    if button =="x" then
        raceMus:stop()
    return end
    if button=="a" then
        flags.drawWall=not flags.drawWall
    end
end

function love.load()
    --[[
    love.profiler=require "profile"
    love.profiler.start()
    --]]
    --hold number of frames since load for update functions
    frames=0
    --setting default background color and 3D to off (I don't have 3ds to test)
    love.graphics.setBackgroundColor(0,.4,0)
    love.graphics.set3D(false)
    -- set default number of horses (move to menu with map later)
    numHorses=9
    -- load font
    tFont=love.graphics.newFont("resources/Terminal2.ttf",14)
    --tFont=love.graphics.newFont(8)
    love.graphics.setFont(tFont)
    -- import sounds
    hitSound={}
    for i=1,3 do
        hitSound[i] = love.audio.newSource("resources/sounds/hit"..i..".wav","static")
    end
    betSound = love.audio.newSource("resources/sounds/placeBets.mp3","stream")
    raceMus = love.audio.newSource("resources/sounds/hrt.ogg","stream")
    raceMus:setLooping(true)
    startTest()
end

function love.update(dt)
    if flags.won then
        wonTime=wonTime+dt
    return end
    cTime=cTime+dt
    frames=frames+1
    if flags.start then
        if cTime<1 then return end
        PYB(dt)
        return
    end
    hspeed=(cTime>90 and 70+math.floor(.33*(cTime-90)) or 70)
    --[[
    -- was using to attempt to optimize old3DS mode
    if math.fmod(frames,100)==99 then
        local report=love.profiler.report(20)
        print(report)
    end
    --]]
    -- check if anything touching carrot
    if math.fmod(frames,3)==0 then
        winscreen.bg,winscreen.txt,winscreen.txt2=checkWin()
    end
    -- move horses
    moveHorses(dt)
end

local function drawBottom()
    --draws the bottom screen text
    love.graphics.setBackgroundColor(0,.4,0)
    love.graphics.setColor(1,1,0)
    if not flags.start then
        local time=string.format("%02d:%02d:%02d",(cTime-pybStageTimer)/60,math.fmod((cTime-pybStageTimer),60),math.fmod((cTime-pybStageTimer)*100,100)*.6)
        love.graphics.print(time,225,10)
        love.graphics.print(time,224,10)
    end
    love.graphics.print("FPS "..love.timer.getFPS(),225,30)
    love.graphics.print("FPS "..love.timer.getFPS(),224,30)
    love.graphics.print("hrt",10,10)
    love.graphics.print("hrt",9,10)
    love.graphics.print(love.hrt,10,30)
    love.graphics.print(love.hrt,9,30)
    love.graphics.print("start: exit",9,80)
    love.graphics.print("start: exit",10,80)
    love.graphics.print("select: new test",9,100)
    love.graphics.print("select: new test",10,100)
    love.graphics.print("up/down: # horses = "..numHorses,9,120)
    love.graphics.print("up/down: # horses = "..numHorses,10,120)
    love.graphics.print("(start new test to update)",8,140)
    love.graphics.print("(start new test to update)",9,140)
    love.graphics.print("x: race music off",9,160)
    love.graphics.print("x: race music off",10,160)
    --]]
end

function love.draw(screen)
    --print time and basic info
    if screen=="bottom" then
        drawBottom()
        love.graphics.print("FPS "..love.timer.getFPS(),225,30)
    return end
    if flags.won then
        if flags.showWinScreen then
            love.graphics.setColor(1,1,1,wonTime-6)
            love.graphics.draw(winscreen.bg)
            love.graphics.setBackgroundColor(.984,.514,.243)
            if wonTime>7 then
                local k=(wonTime>8 and 1 or wonTime-7)
                if winscreen.txt2.scale and k>winscreen.txt2.scale then
                    love.graphics.draw(winscreen.txt2.txt,40,240,0,k,k,0,100)
                return end
                love.graphics.draw(winscreen.txt,40,240,0,k,k,0,39)
            end
            return
        end

        love.graphics.translate(xgc,ygc)
        love.graphics.scale((wonTime<2) and 1 or (wonTime-1)^3)
        love.graphics.translate(-xgc,-ygc)
        if wonTime>6 then
            flags.showWinScreen=true
        end
    end
    love.graphics.setColor(1,1,1)
    love.graphics.draw(map.bg,0,0)
    -- draw horses
    for _,v in ipairs(horses) do
        love.graphics.draw(v.icon,v._center.x,v._center.y,0,.53,.53,v.icon:getWidth()/2,v.icon:getHeight()/2)
    end
    if flags.drawWall then
        for _,v in ipairs(map.walls) do
            v:draw("fill")
        end
    end
    -- draw place bets box
    if flags.start then
        if pybbox.stage==0 then
            love.graphics.setColor(1,1,1,1.2+pybStageTimer-cTime)
        end
        love.graphics.draw(pybbox.icon,pybbox.x,pybbox.y,0,(125/559),(125/559))
        love.graphics.setColor(1,1,1,1)
        love.graphics.draw(gate,unpack(map.gatePos))
    end

end