---[[
    require"nest".init({console="3ds",scale=2})
if arg[2] == "debug" then
    require("lldebugger").start()
end
--]]

--set font early
tFont=love.graphics.newFont("resources/Terminal2.ttf",14)
tFont:setLineHeight(1.3)
--love.graphics.setDefaultFilter("nearest","nearest")

-- initialize a few local tables
local map,winscreen,control={},{},{}
local fullHorseList,fullMapList= require "menu"()

-- decided to rework trial
local trial={}
for _,v in ipairs(fullMapList) do
    trial[v]=0
end
love.graphics.set3D(false)

-- function variables
local draw = function()end

-- making these local to file:
local flags,hspeed,cTime,pybStageTimer,wonTime,betSound,pybbox,xgc,ygc,numHorses,frames,gate,chline,cmapname,raceMus,inumHorses
local thread = love.thread.newThread("GB.lua")
local inHorses,outHorses,hIcons={},{},{}
local controlChan,inHorChan,outHorChan

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
            frames=0
            controlChan:push("go")
            flags.start=false
            love.update=control.mainupdate
            draw=control.maindraw
            --betSound:stop()
            love.audio.play(raceMus)
            pybbox.allIcons=nil
            gate=nil
            return
        end
        pybbox.icon=pybbox.allIcons[pybbox.stage]
    end
end

local function checkWin()
    -- checks if collision with goal
    if controlChan:peek() then
        local h=chline[controlChan:pop()]
        love.update=control.winupdate
        draw=control.windraw
        hspeed=0
        love.audio.stop()
        local winsound=love.audio.newSource("resources/sounds/winsongs/"..h.."Win.mp3","stream")
        winsound:play()
        local winImg=love.graphics.newImage("resources/winscreens/win"..h..".png")
        local winTxt=love.graphics.newImage("resources/winscreens/txt"..h..".png")
        local longNames={RES=.76,COM=.96,YEL=.93,FFF=0}
        local winTxt2,s
        if longNames[h] then
            winTxt2=love.graphics.newImage("resources/winscreens/txt"..h.."2.png")
            s=longNames[h]
        end
        return winImg,winTxt,{txt=winTxt2,scale=s}
    end
    return nil,nil,nil
end

-- function to restart everything or initialize for first time 
local function startTest(hline,mapname)
    mapname=mapname or cmapname
    chline,cmapname = hline or chline,mapname
    -- reset background color
    love.graphics.setBackgroundColor(0,.4,0)
    -- reset flags + timers + horse array
    flags={start=true}
    love.update,love.draw,draw=control.startupdate,Maindraw,control.startdraw
    pybStageTimer,wonTime,cTime=0,0,0
    inHorses,outHorses,hIcons={},{},{}
    -- reset sounds
    love.audio.stop()
    -- initialize collision map
    map= require("maps")(mapname)
    xgc,ygc=unpack(map.goal)
    numHorses=math.min(numHorses,#map.horsePos/2)
    inumHorses=numHorses
    -- initialize collision
    thread:start(mapname,math.min(#chline,numHorses))
    controlChan=love.thread.getChannel("control")
    inHorChan=love.thread.getChannel("inHorses")
    outHorChan=love.thread.getChannel("outHorses")
    -- shuffle horse list
    for i = #chline, 2, -1 do
        local j = love.math.random(i)
        chline[i], chline[j] = chline[j], chline[i]
    end
    -- add horses to the scene
    for i,h in ipairs(chline) do
        if i>numHorses then break end
        inHorses[i]={map.horsePos[2*i-1],map.horsePos[2*i],.2}
        hIcons[i]=love.graphics.newImage("resources/horses/"..h..".png")
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
    love.hrt = "e3DSm"..mapname:sub(-1).."t"..trial[mapname]
    flags.resetting=false
    outHorses=outHorChan:demand(10)
end

local function gamepadmain(_,button)
    if button=="start" then
        controlChan:push("end")
        inHorChan:push({})
        love.audio.stop()
        love.graphics.setColor(1,1,1)
        thread:wait()
        controlChan:clear()
        inHorChan:clear()
        outHorChan:clear()
        return love.mainStartup()
    end
    if button=="back" and not flags.resetting then
        controlChan:push("end")
        inHorChan:push({})
        thread:wait()
        controlChan:clear()
        inHorChan:clear()
        outHorChan:clear()
        flags.resetting=true
        return startTest()
    end
    if button=="dpup" then
        numHorses=numHorses<math.min(#chline,#map.horsePos/2) and numHorses+1 or math.min(#chline,#map.horsePos/2)
    return end
    if button=="dpdown" then
        numHorses=numHorses>1 and numHorses-1 or 1
    return end
    if button =="x" then
        if raceMus:isPlaying() then
            return love.audio.stop(raceMus)
        end
        return raceMus:play()
    end
end

---[[
function love.mainload(hline,mapname,bgmname)
    --hold number of frames since load for update functions
    --increment trials
    trial[mapname]=trial[mapname]+1
    --setting default background color and 3D to off (I don't have 3ds to test)
    love.graphics.setBackgroundColor(0,.4,0)
    -- set default number of horses (move to menu with map later)
    numHorses=math.min(6,#hline)
    --set font
    love.graphics.setFont(tFont)
    -- import sounds
    if bgmname and bgmname~="" then
        raceMus = love.audio.newSource("resources/sounds/BGM/"..bgmname,"stream")
        raceMus:setLooping(true)
    else
        raceMus = love.audio.newSource("resources/sounds/hit1.wav","static")
        raceMus:setLooping(false)
    end
    betSound = love.audio.newSource("resources/sounds/placeBets.mp3","stream")
    love.gamepadpressed=gamepadmain
    return startTest(hline,mapname)
end
--]]

function control.startupdate(dt)
    cTime=cTime+dt
    if cTime<1 then return end
    PYB(dt)
end

function control.mainupdate(dt)
    cTime=cTime+dt
    frames=frames+1
    hspeed=(cTime>90 and 70+math.floor(.33*(cTime-90)) or 70)
    -- check if anything touching carrot
    winscreen.bg,winscreen.txt,winscreen.txt2=checkWin()
    -- move horses
    for i,h in ipairs(inHorses) do
        local v=outHorses[i]
        h[3]=h[3]-dt
        if v[3] then
            h[3]=.2
            v[3]=false
        end
        h[1],h[2]=h[1]+v[1]*hspeed*dt,h[2]+v[2]*hspeed*dt
        -- soundBuffer to prevent horses from making multiple hit sounds when hitting a wall once
    end
    if frames==2 then
        frames=0
        inHorChan:push({inHorses,2*love.timer.getAverageDelta(),hspeed})
        outHorses=outHorChan:demand()
    end
end

function control.winupdate(dt)
    wonTime=wonTime+dt
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
    --love.graphics.print("FPS "..love.timer.getFPS(),225,30)
    love.graphics.print("FPS "..love.timer.getFPS(),224,30)
    love.graphics.print("hrt\n"..love.hrt,10,10)
    love.graphics.print("hrt\n"..love.hrt,9,10)
    love.graphics.print("start: main menu\nselect: restart test\n\nup/down: # horses = "..numHorses.."\n(restart to update)\n\nx: toggle race music",9,80)
    love.graphics.print("start: main menu\nselect: restart test\n\nup/down: # horses = "..numHorses.."\n(restart to update)\n\nx: toggle race music",10,80)
end

function control.startdraw()
    love.graphics.setColor(1,1,1)
    love.graphics.draw(map.bg,0,0)
    -- draw horses
    for i,v in ipairs(inHorses) do
        love.graphics.draw(hIcons[i],v[1],v[2],0,.53,.53,16,16)
    end
    -- draw place bets box
    if pybbox.stage==0 then
        love.graphics.setColor(1,1,1,1.2+pybStageTimer-cTime)
    end
    love.graphics.draw(pybbox.icon,pybbox.x,pybbox.y,0,1,1)
    love.graphics.setColor(1,1,1,1)
    for i=1,(#map.gatePos/5) do
        if inumHorses>map.gatePos[5*i-4] then
            love.graphics.draw(gate,map.gatePos[5*i-3],map.gatePos[5*i-2],0,map.gatePos[5*i-1],map.gatePos[5*i])
        end
    end
    return
end

function control.maindraw()
    love.graphics.setColor(1,1,1)
    love.graphics.draw(map.bg,0,0)
    -- draw horses
    for i,v in ipairs(inHorses) do
        love.graphics.draw(hIcons[i],v[1],v[2],0,.53,.53,16,16)
    end
end

function control.windraw()
    love.graphics.translate(xgc,ygc)
    love.graphics.scale((wonTime<2) and 1 or (wonTime-1)^3)
    love.graphics.translate(-xgc,-ygc)
    if wonTime>6 then
        draw=control.winscreendraw
    end
    return control.maindraw()
end

function control.winscreendraw()
    love.graphics.setColor(.984,.514,.243)
    love.graphics.rectangle("fill",0,0,400,240)
    love.graphics.setColor(1,1,1,wonTime-6)
    love.graphics.draw(winscreen.bg)
    if wonTime>7 then
        local k=(wonTime>8 and 1 or wonTime-7)
        if winscreen.txt2.scale and k>winscreen.txt2.scale then
            return love.graphics.draw(winscreen.txt2.txt,40,240,0,k,k,0,100)
        end
        return love.graphics.draw(winscreen.txt,40,240,0,k,k,0,39)
    end
end

function Maindraw(screen)
    if screen=="bottom" then
        return drawBottom()
    end
    return draw()
end