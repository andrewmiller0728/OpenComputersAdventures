local component = require("component")
local computer = require("computer")
local robot = require("robot")
local shell = require("shell")
local sides = require("sides")

--[[ SET UP ]]--

-- Program must be run on a robot
if not component.isAvailable("robot") then
    io.stderr:write("can only run on robots")
    return
end
local r = component.robot

-- Take in command line arguments
local args, ops = shell.parse(...)
if #args ~= 3 then
    io.write("Usage: stripMine [-s] <length> <width_l> <width_r>\n")
    io.write("\t<length>: length of the strip mine")
    io.write("\t<width_l>: width of junction left arm")
    io.write("\t<width_r>: width of junction right arm")
    io.write("\t-s: shutdown when done")
    return
end

-- Validate command line arguments
local length, widthL, widthR = tonumber(args[1]), tonumber(args[2]), tonumber(args[3])
if not length or not widthL or not widthR then
    io.stderr:write("Invalid size parameters")
    return
end

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

--[[ MAIN ]]--

-- Build T junction
for i = 0, math.floor(length / 3) do
    -- Root
    turnTowards(sides.forward)
    local j = 0
    repeat
        step()
        j = j + 1
    until j >= 3

    -- Center point
    local cx, cy, cz = x, y, z

    -- Left arm
    turnTowards(sides.left)
    j = 0
    repeat
        step()
        j = j + 1
    until j >= widthL

    -- Right arm
    moveTo(cx, cy, cz)
    turnTowards(sides.right)
    j = 0
    repeat
        step()
        j = j + 1
    until j >= widthR

    -- Re-center
    moveTo(cx, cy, cz)
end
turnTowards(sides.forward)
for i = 0, length % 3 do
    step()
end

-- return home
moveTo(0, 0, 0)
turnTowards(0)
checkedDrop(true)

-- if [-s] flag, shutdown
if ops.s then
    computer.shutdown()
end