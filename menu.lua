local Menu={}
-- all locals that can be deleted after leaving menu
local cursor,menuSize,page,cursPos,menubgB,menubgT,cursorI,menuTxt,btmTxt,mark,hSelectList,hIcons,menuTimer,txtCycle,maps,gpMenuFunctions,logo,logo2,cMapIndex
--update with any future horses added
local fullHorseList={"MRY","CYN","SUP","YEL","BUL","KNB","COM","BOX","RES","AMF","BIN","NGT","FF8","OOB","FFF"}
--update with future maps added
local fullMapList={"map1","map3","map4"}
local fullBGMList={"AMFSUPDuel.ogg","Custom1fix.ogg","tbnewlowqual.ogg"}
local BGMTransList={"AMF vs SUP","Lazy Horse Daily","Place Your Bets!"}
love.graphics.setFont(tFont)
local bgm = love.audio.newSource("resources/sounds/stupidhorsehrt.ogg","stream")
bgm:setLooping(true)

hSelectList={}
    for _,n in ipairs(fullHorseList) do
        hSelectList[n]=false
    end

local function menuUnload(hline,mapname,bgmname)
---@diagnostic disable-next-line: unbalanced-assignments
    cursor,menuSize,page,cursPos,menubgB,menubgT,cursorI,menuTxt,btmTxt,mark,hSelectList,hIcons,menuTimer,txtCycle,maps,gpMenuFunctions,logo,logo2,bgm,cMapIndex=nil
    collectgarbage("collect")
    return love.mainload(hline,mapname,bgmname)
end

function love.mainStartup()
    --start music if not playing
    if not bgm then
        bgm = love.audio.newSource("resources/sounds/stupidhorsehrt.ogg","stream")
        bgm:setLooping(true)
    end
    if not bgm:isPlaying() then
        bgm:play()
    end
    --recreate hSelectList if it was deleted
    if not hSelectList then
        hSelectList={}
        for _,n in ipairs(fullHorseList) do
            hSelectList[n]=false
        end
    end
    --set graphic items
    menubgB=love.graphics.newImage("resources/menu/bottom/mainmenu.png")
    menubgT=love.graphics.newImage("resources/menu/top/menutop.png")
    cursorI=love.graphics.newImage("resources/menu/bottom/bigcursor.png")
    logo=love.graphics.newImage("resources/menu/top/logo.png")
    logo2=love.graphics.newImage("resources/menu/top/logo2.png")

    cursor,menuSize,btmTxt,menuTxt,mark,hIcons=1,2,nil,nil,nil,nil
    cursPos={{9,72},{169,72}}
    love.update=nil
    love.draw=Menu.drawMenuMain

    --move to intro later
    love.gamepadpressed=Menu.gamepadMenu
    --defining menu functions
    gpMenuFunctions={}
    gpMenuFunctions.b=nil
    gpMenuFunctions.dpup=nil
    gpMenuFunctions.dpdown=nil
    gpMenuFunctions.dpright=function() cursor=math.fmod(cursor,menuSize)+1 end
    gpMenuFunctions.dpleft=function() cursor=(cursor==1 and menuSize or cursor-1) end
    gpMenuFunctions.leftshoulder=nil
    gpMenuFunctions.rightshoulder=nil
    gpMenuFunctions.start=love.event.quit
    gpMenuFunctions.a=function ()
        if cursor==1 then
            return menuUnload({unpack(fullHorseList)},fullMapList[love.math.random(1,#fullMapList)],fullBGMList[love.math.random(1,#fullBGMList)])
        end
        return Menu.horseStartup()
    end
end

function Menu.horseStartup()
    maps=nil
    -- load images
    menubgB=love.graphics.newImage("resources/menu/bottom/submenu.png")
    cursorI=love.graphics.newImage("resources/menu/bottom/smallcursor.png")
    btmTxt={love.graphics.newImage("resources/menu/bottom/bottomtxt1.png"),
    love.graphics.newImage("resources/menu/bottom/bottomtxt2Horse.png"),
    love.graphics.newImage("resources/menu/bottom/bottomtxt3.png")}
    menuTxt=love.graphics.newImage("resources/menu/bottom/menutxtHorse.png")
    mark=love.graphics.newImage("resources/menu/bottom/check.png")
    hIcons={}
    for _,v in ipairs(fullHorseList) do
        hIcons[v]=love.graphics.newImage("resources/horses/"..v..".png")
    end

    love.update=Menu.updateMenu
    menuTimer=0
    love.draw=Menu.drawMenuHorse

    cursPos={{43,70},{124,70},{205,70},{43,148},{124,148},{205,148}}
    cursor,menuSize,page,txtCycle=1,6,0,0

    --define menu inputs horse screen
    gpMenuFunctions.cMenuList=fullHorseList
    gpMenuFunctions.dpright=function()
        cursor=cursor+1
        if cursor==menuSize+1 then
            cursor=1
            if #gpMenuFunctions.cMenuList-6*(page+1)>0 then
                page=page+1
                menuSize=math.min(6,#gpMenuFunctions.cMenuList-page*6)
            return end
            page=0
            menuSize=math.min(6,#gpMenuFunctions.cMenuList)
        end
    end
    gpMenuFunctions.dpleft=function()
        cursor=cursor-1
        if cursor==0 then
            if page==0 then
                page=math.floor(#gpMenuFunctions.cMenuList/6-.01)
                menuSize=#gpMenuFunctions.cMenuList-page*6
                cursor=menuSize
            return end
            page=page-1
            menuSize=6
            cursor=6
        end
    end
    gpMenuFunctions.dpup=function ()
        local temp = cursor==3 and 6 or math.fmod(cursor+3,6)
        if temp>menuSize then temp=cursor end
        cursor=temp
    end
    gpMenuFunctions.dpdown=gpMenuFunctions.dpup
    gpMenuFunctions.b=love.mainStartup
    gpMenuFunctions.a=function()
        hSelectList[fullHorseList[cursor+6*page]]=not hSelectList[fullHorseList[cursor+6*page]]
    end
    gpMenuFunctions.rightshoulder=function()
        cursor=1
        if (page+1)*6>=#gpMenuFunctions.cMenuList then
            page=0
            menuSize=math.min(6,#gpMenuFunctions.cMenuList)
        return end
        page=page+1
        menuSize=math.min(6,#gpMenuFunctions.cMenuList-page*6)
    end
    gpMenuFunctions.leftshoulder=function()
        cursor=1
        if page==0 then
            page=math.floor(#gpMenuFunctions.cMenuList/6-.01)
            menuSize=#gpMenuFunctions.cMenuList-page*6
        return end
        page=page-1
        menuSize=math.min(6,#gpMenuFunctions.cMenuList)
    end
    local function hasFalse(t)
        for _,v in pairs(t) do
            if not v then return true end
        end
        return false
    end
    gpMenuFunctions.back=function()
        local bool= hasFalse(hSelectList)
        for k,_ in pairs(hSelectList) do
            hSelectList[k]=bool
        end
    end
    gpMenuFunctions.start=Menu.mapStartup
end

function Menu.mapStartup()
    mark=nil
    hIcons=nil
    page,cursor,txtCycle=0,1,0
    menuSize=math.min(#fullMapList,6)
    maps={}
    for _,v in ipairs(fullMapList) do
        maps[#maps+1] = love.graphics.newImage("resources/maps/preview/"..v..".png")
    end
    menuTxt=love.graphics.newImage("resources/menu/bottom/menutxtMap.png")
    btmTxt[2],btmTxt[3]=love.graphics.newImage("resources/menu/bottom/bottomtxt2Map.png"),nil

    love.draw=Menu.drawMenuMaps
    gpMenuFunctions.cMenuList=fullMapList
    gpMenuFunctions.start=nil
    gpMenuFunctions.back=nil
    gpMenuFunctions.b=Menu.horseStartup
    gpMenuFunctions.a=function()
        cMapIndex=cursor+6*page
        return Menu.bgmStartup()
    end
end

function Menu.bgmStartup()
    page,cursor,txtCycle=0,1,0
    menuSize=math.min(#fullBGMList,6)
    menuTxt=love.graphics.newImage("resources/menu/bottom/menutxtBGM.png")
    love.draw=Menu.drawMenuBGM
    gpMenuFunctions.cMenuList=fullBGMList
    gpMenuFunctions.b=Menu.mapStartup
    gpMenuFunctions.a=function()
        --transform hSelectList to string name array of selected horses
        local temp={}
        for k,v in pairs(hSelectList) do
            if v then temp[#temp+1]=k end
        end
        return menuUnload(temp,fullMapList[cMapIndex],fullBGMList[cursor+6*page])
    end
end

function Menu.gamepadMenu(_,button)
    local func = gpMenuFunctions[button]
    if func then
        return func()
    end
end

function Menu.updateIntroVid(dt)
    love.update=Menu.updateMenu
end

function Menu.updateMenu(dt)
    menuTimer=menuTimer+dt
    txtCycle=math.floor(math.fmod(.3*menuTimer,#btmTxt))+1
end

function Menu.drawIntroVid(screen)
    love.draw=Menu.drawMenuMain
end

local function drawTop()
    love.graphics.draw(menubgT)
    love.graphics.draw(logo,51,7)
    love.graphics.draw(logo2,210,56+math.floor(5*math.sin(love.timer.getTime())+.5))
end


function Menu.drawMenuMain(screen)
    if screen=="bottom" then
        love.graphics.draw(menubgB)
        return love.graphics.draw(cursorI,cursPos[cursor][1],cursPos[cursor][2],0,1,1,6,6)
    end
    return drawTop()
end

function Menu.drawMenuHorse(screen)
    if screen=="bottom" then
        love.graphics.draw(menubgB)
        love.graphics.draw(menuTxt,62,37)
        love.graphics.draw(btmTxt[txtCycle],9,224)
        love.graphics.draw(cursorI,cursPos[cursor][1],cursPos[cursor][2],0,1,1,4,4)
        for i=1,menuSize do
            love.graphics.draw(hIcons[fullHorseList[i+6*page]],cursPos[i][1],cursPos[i][2],0,1,1,-19,-10)
            if hSelectList[fullHorseList[i+6*page]] then
                love.graphics.draw(mark,cursPos[i][1],cursPos[i][2],0,1,1,-7,-7)
            end
            love.graphics.setColor(1,1,0)
            love.graphics.print(fullHorseList[i+6*page],cursPos[i][1]+21,cursPos[i][2]+47)
            love.graphics.print(fullHorseList[i+6*page],cursPos[i][1]+22,cursPos[i][2]+47)
            love.graphics.setColor(1,1,1)
        end
    return end
    return drawTop()
end

function Menu.drawMenuMaps(screen)
    if screen=="bottom" then
        love.graphics.draw(menubgB)
        love.graphics.draw(menuTxt,62,37)
        love.graphics.draw(btmTxt[txtCycle],9,224)
        love.graphics.draw(cursorI,cursPos[cursor][1],cursPos[cursor][2],0,1,1,4,4)
        love.graphics.setColor(1,1,0)
        for i=1,menuSize do
            love.graphics.print(fullMapList[i+6*page],cursPos[i][1]+19,cursPos[i][2]+25)
            love.graphics.print(fullMapList[i+6*page],cursPos[i][1]+18,cursPos[i][2]+25)
        end
        love.graphics.setColor(1,1,1)
    return end
    return love.graphics.draw(maps[cursor+6*page])
end

function Menu.drawMenuBGM(screen)
    if screen=="bottom" then
        love.graphics.draw(menubgB)
        love.graphics.draw(menuTxt,62,37)
        love.graphics.draw(btmTxt[txtCycle],9,224)
        love.graphics.draw(cursorI,cursPos[cursor][1],cursPos[cursor][2],0,1,1,4,4)
        love.graphics.setColor(1,1,0)
        for i=1,menuSize do
            love.graphics.printf(BGMTransList[i+6*page],cursPos[i][1]+4,cursPos[i][2]+13,62,"center")
            love.graphics.printf(BGMTransList[i+6*page],cursPos[i][1]+5,cursPos[i][2]+13,62,"center")
        end
        love.graphics.setColor(1,1,1)
    return end
    return drawTop()
end

love.mainStartup()
return function () return fullHorseList,fullMapList end
