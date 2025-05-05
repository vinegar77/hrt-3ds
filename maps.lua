local Maps = {map0={},map1={}}
Maps.map0.walls = {{0,0, 400,0, 400,15, 0,15},
{0,230, 400,230, 400,240, 0,240},
{0,0, 5,0, 5,240, 0,240},
{395,0, 395,240, 400,240, 400,0}}

-- new better curve code
local function curve2(x1,y1,x2,y2,x3,y3,xc,yc,A,B,smooth)
    yc=math.floor(yc+.5)
    local c={x3,y3,x1,y1}
    local step=math.floor((x2-x1)/smooth +.5)
    local tpoint = math.floor(B*math.sqrt(1-A^-2*((x1+step)-xc)^2)+.5)
    local sign= (math.abs(y3-(yc+tpoint))<math.abs(y3-(yc-tpoint)) and 1 or -1)
        for i=1,smooth-1 do
            c[#c+1]=(x1+step*i)
            c[#c+1]=(sign*math.floor(B*math.sqrt(1-(A^-2*((x1+step*i)-xc)^2))+.5)+yc)
        end
    table.insert(c,x2)
    table.insert(c,y2)
    return c
end

Maps.map1.walls = {
-- main walls
{0,0, 400,0, 400,10, 0,10},
{0,235, 400,235, 400,240, 0,240},
{0,0, 45,0, 45,240, 0,240},
{355,0, 355,240, 400,240, 400,0},
-- 2 triangle at start
{112,10, 150,39, 171,10},
{123,93, 146,71, 167,93},
-- middle wall
{0,93, 234,93, 234,96, 0,96},
-- 2nd room curves
{223,93, 234,89, 234,93},
curve2(218,10,260,32,259,10,217.5,51.5,46.5,41.5,3),
curve2(263,61,256,74,263,74,217.5,51.5,46.5,41.5,2),
--hall between 2nd room and circle room
{260,32, 284,32, 284,30},
{263,61, 282,61, 282, 63},
-- circle room
curve2(284,32,318,11,284,11,317.5,48.5,37.5,37.5,2),
curve2(355,49,318,11,355,11,317.5,48.5,37.5,37.5,5),
curve2(355,49,318,86,355,86,317.5,48.5,37.5,37.5,5),
curve2(282,61,318,86,282,86,317.5,48.5,37.5,37.5,2),
{282,86, 355,86, 355,89},
-- hallway 1
{234,89, 271,126, 236,126},
{256,74, 294,105, 276, 74},
-- room 3
{294,104,312,102,294,102},
curve2(312,102,354,140,354,102,311.5,139.5,42.5,37.5,5),
curve2(312,177,354,140,354,177,311.5,139.5,42.5,37.5,5),
{296,175,312,177,296,177},
{271,126,269,130,269,126},
{270,147,268,130,269,147},
--hallway 2
{270,147, 235,163, 235,147},
{296,175, 267,195, 330,175},
--room 4
curve2(212,160,235,163,235,160,211.5,197.5,54.5,37.5,2),
curve2(212,160,163,179,163,160,211.5,197.5,54.5,37.5,3),
{266,197, 267,195, 266,195},
curve2(266,197,212,235,266,235,211.5,197.5,54.5,37.5,5),
curve2(160,211,212,235,160,235,211.5,197.5,54.5,37.5,3),
--hallway 3
{163,179, 130,174, 163,174},
{123,212, 160,211, 160,216},
--big circle room
curve2(123,212,90,229,123,229,90,188,41,41,3),
curve2(49,188,90,229,49,229,90,188,41,41,7),
curve2(49,188,72,151,49,151,90,188,41,41,4),
{130,174, 126,168, 130,168},
{98,147, 107,150, 107,147},
--bonus hall
{72,151, 70,144, 70,151},
{98,147, 98,140, 100,140},
--bonus circle room
curve2(70,144,51,121,51,144,80,121,29,24,4),
curve2(80,97,51,121,51,97,80,121,29,24,5),
curve2(80,97,109,121,109,97,80,121,29,24,5),
curve2(98,140,109,121,109,140,80,121,29,24,3),
--hallway 4
{126,166, 159,148, 159,166},
{107,150, 131,131, 125,131},
--carrot room
{130,127, 131,131, 130,131},
{159,148, 183,150, 159,150},
curve2(130,127,183,104,130,104,182.5,127,52.5,23,5),
curve2(235,127,183,104,235,104,182.5,127,52.5,23,4),
curve2(235,127,183,150,235,150,182.5,127,52.5,23,4),
}
Maps.map1.goal={196,124,6}
Maps.map1.horsePos={57,74, 79,31, 98,69, 57,46, 79,61, 98,20, 58,21, 99,40, 79,83}
Maps.map1.gatePos={113,4}

--Less memory-intensive option as all local Maps variables no longer need to stay loaded
return function(HC,mapname)
    local m = {
        --walls={}
        }
    assert(Maps[mapname],"map does not exist")
    for _,v in ipairs(Maps[mapname].walls) do
        --print(v)
        --table.insert(m.walls,HC.polygon(unpack(v)))
        HC.polygon(unpack(v))
    end
    m.goal=HC.circle(unpack(Maps[mapname].goal))
    m.bg=love.graphics.newImage("resources/maps/"..mapname..".png")
    m.gatePos=Maps[mapname].gatePos
    m.horsePos=Maps[mapname].horsePos
    return m
end

--return Maps