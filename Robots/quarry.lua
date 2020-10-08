local component = require("component")
local computer = require("computer")
local robot = require("robot")
local shell = require("shell")
local sides = require("sides")

--[[ Set Up ]]--

-- Program must be run on a robot
if not component.isAvailable("robot") then
    io.stderr:write("can only run on robots")
    return
end

-- Take in command line arguments
local args, ops = shell.parse(...)
if #args ~= 2 then
    io.write("Usage: quarry [-s] <size_xz> <size_y>\n")
    io.write(" x and z are on the horizontal plane, y is the vertical axis\n")
    io.write(" <size_xz> is the side length of the square quarry")
    io.write(" <size_y> is the number of 3 block layers to mine\n")
    io.write(" -s: shutdown when done")
    return
end

-- Validate command line arguments
local sizeX, sizeY = tonumber(args[1]), tonumber(args[2])
if not sizeX or not sizeY then
    io.stderr:write("Invalid size parameters")
    return
end

local r = component.robot

--[[ MOVEMENT ]]--

-- (x, y, z) coordinates and f rotation {int | 0 <= int <= 3}
local x, y, z, f = 0, 0, 0, 0
local dropping = false -- avoid recursing into drop()
local delta = {[0] = function() x = x + 1 end, [1] = function() y = y + 1 end,
               [2] = function() x = x - 1 end, [3] = function() y = y - 1 end}

local function turnRight()
    robot.turnRight()
    f = (f + 1) % 4
end

local function turnLeft()
    robot.turnLeft()
    f = (f - 1) % 4
end

local function turnTowards(side)
    if f == side - 1 then
      turnRight()
    else
        while f ~= side do
            turnLeft()
        end
    end
end

local checkedDrop -- forward declaration

local function clearBlock(side, cannotRetry)
    while r.suck(side) do
        checkedDrop()
    end
    local result, reason = r.swing(side)
    if result then
        checkedDrop()
    else
        local _, what = r.detect(side)
        if cannotRetry and what ~= "air" and what ~= "entity" then
        return false
        end
    end
    return true
end

local function tryMove(side)
    side = side or sides.forward
    local tries = 10
    while not r.move(side) do
        tries = tries - 1
        if not clearBlock(side, tries < 1) then
            return false
        end
    end
    if side == sides.down then
        z = z + 1
    elseif side == sides.up then
        z = z - 1
    else
        delta[f]()
    end
    return true
end

local function moveTo(tx, ty, tz, backwards)
    local axes = {
    function()
        while z > tz do
            tryMove(sides.up)
        end
        while z < tz do
            tryMove(sides.down)
        end
    end,
    function()
        if y > ty then
            turnTowards(3)
            repeat tryMove() until y == ty
        elseif y < ty then
            turnTowards(1)
            repeat tryMove() until y == ty
        end
    end,
    function()
        if x > tx then
            turnTowards(2)
            repeat tryMove() until x == tx
        elseif x < tx then
            turnTowards(0)
            repeat tryMove() until x == tx
        end
    end
    }
    if backwards then
        for axis = 3, 1, -1 do
            axes[axis]()
        end
    else
        for axis = 1, 3 do
            axes[axis]()
        end
    end
end

function checkedDrop(force)
    local empty = 0
    for slot = 1, 16 do
        if robot.count(slot) == 0 then
            empty = empty + 1
        end
    end
    if not dropping and empty == 0 or force and empty < 16 then
        local ox, oy, oz, of = x, y, z, f
        dropping = true
        moveTo(0, 0, 0)
        turnTowards(2)

        for slot = 1, 16 do
            if robot.count(slot) > 0 then
            robot.select(slot)
            local wait = 1
            repeat
                if not robot.drop() then
                os.sleep(wait)
                wait = math.min(10, wait + 1)
                end
            until robot.count(slot) == 0
            end
        end
        robot.select(1)

        dropping = false
        moveTo(ox, oy, oz, true)
        turnTowards(of)
    end
end

local function step()
    clearBlock(sides.down)
    if not tryMove() then
        return false
    end
    clearBlock(sides.up)
    return true
end
  
local function turn(i)
    if i % 2 == 1 then
        turnRight()
    else
        turnLeft()
    end
end

local function digLayer()
    for j = 1, sizeX do
        for k = 1, sizeX - 1 do
            if not step() then
                return false
            end
        end
        if j < sizeX then
            -- End of a normal line, move the "cap".
            turn(j)
            if not step() then
                return false
            end
            turn(j)
        else
            turnRight()
            if sizeX % 2 == 1 then
                turnRight()
            end
            for l = 1, 3 do
                if not tryMove(sides.down) then
                    return false
                end
            end
        end
        computer.beep()
    end
    computer.beep()
    computer.beep()
    return true
end

local i = 1
local layerDug = digLayer()
while i < sizeY and layerDug do
    i = i + 1

    -- if tool is broken/missing, return to retrieve a new tool

    local batteryMin = 0.15
    local batteryMax = 0.95
    local currentBattery = computer.energy() / computer.maxEnergy()
    if currentBattery <= batteryMin then
        local cx, cy, cz, cf = x, y, z, f
        moveTo(0, 0, 0)
        turnTowards(0)
        repeat until currentBattery >= batteryMax
        moveTo(cx, cy, cz)
        turnTowards(f)
    end

    layerDug = digLayer() 
end
moveTo(0, 0, 0)
turnTowards(0)
checkedDrop(true)

if ops.s then
    computer.shutdown()
end