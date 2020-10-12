-- Author: Andrew Miller
-- Date: 2020-10-11

-- Lua Conventions:
-- https://ocdoc.cil.li/lua_conventions

-- [[ PLANT FARMING ROBOT ]]--
-- Goals:
--      - Sowing seeds in tilled soil
--      - Maintaining grounds
--      - Harvest at appropriate intervals
--      - Organize storage of resouces and products
--      - Have a personal UX
--      - Keep track of production rate

-- Resources:
--      - https://ocdoc.cil.li/api:event
--      - https://ocdoc.cil.li/api:robot
--      - https://ocdoc.cil.li/api:computer
--      - https://ocdoc.cil.li/api:thread
--      - https://ocdoc.cil.li/api:sides
--
--      - https://ocdoc.cil.li/component:robot
--      - https://ocdoc.cil.li/component:computer

---------- ---------- ---------- ---------- ---------- ---------- ----------


-- [[ VARIABLES ]] --
local LOW_BATTERY = 0.15
local WHEAT_TIMER = 30 * 60 -- 30 minutes in seconds

local harvestTimer

-- Charger Location
local chx, chy, chz
-- Farm Southeast Corner
local fmx, fmy, fmz
-- Farm Square Dimensions
local fmw, fmh

---------- ---------- ---------- ---------- ---------- ---------- ----------


-- [[ SET UP]] --

local component = require("component")
local robotComp = component.robot
local computer = require("computer")
local robot = require("robot")
local shell = require("shell")
local sides = require("sides")
local event = require("event")
local thread = require("thread")

-- Program must be run on a robot
if not component.isAvailable("robot") then
    io.stderr:write("Error - Can only run on robots")
    return
end

-- Take in command line arguments
local args, ops = shell.parse(...)
if #args ~= 1 then
    io.write("Usage: farmer [-s] <filename>\n")
    io.write("  <filename> defines the layout of the farm")
    io.write("  -s: shutdown when done")
    return
end

-- Validate command line arguments
local filename = args[1]
if not filename then
    io.stderr:write("Error - No file defined")
    return
elseif false then -- TODO: if file not found then
    io.stderr:write("Error - File not found")
    return
end

-- TODO: Parse farm file and build database
local farmFile = io.open(filename, "r")
for i = 1, io.lines() do
    io.write(io.read("l"))
end
io.close(farmFile)

-- Save init position and orientation data
local x, y, z, o = 0, 0, 0, 0

---------- ---------- ---------- ---------- ---------- ---------- ----------


-- [[ COMMON TASKS ]] --

local function getBatteryLevel()
    return computer.energy() / computer.maxEnergy()
end

local function checkBattery()
    local batteryLevel = getBatteryLevel()
    if (batteryLevel <= LOW_BATTERY) then
        computer.pushSignal("CHARGE", batteryLevel)
    end
    return
end

local function replaceTool(tool)
    -- Discard current tool
    -- Retrieve new tool from storage
    -- BONUS: if no tools in storage, make one
    return
end

-- Tills dirt block below with a hoe
local function tillBelow()
    if not robot.count(1) then
        replaceTool("HOE")
    end

    robot.select(5) -- select first inventory slot
    if not robot.compareDown() then
        robot.swingDown()
    end

    return
end

local function sowBelow()
    -- if there aren't any seeds in inventory, get seeds
    -- select seeds from inventory
    -- if the ground below isn't sown, sow a seed
    return
end

---------- ---------- ---------- ---------- ---------- ---------- ----------


-- [[ MOVEMENT ]] --

-- Turns to specified orientation
local function turnTo(to)
    if o == to - 1 then
        robot.turnRight()
        o = (o + 1) % 4
    else
        while o ~= to do
            robot.turnLeft()
            o = (o - 1) % 4
        end
    end
end

local function movePosX()
    turnTo(3)
    robot.forward()
    x = x + 1
    return
end

local function moveNegX()
    turnTo(1)
    robot.forward()
    x = x - 1
    return
end

local function movePosY()
    robot.up()
    y = y + 1
    return
end

local function moveNegY()
    robot.down()
    y = y - 1
    return
end

local function movePosZ()
    turnTo(0)
    robot.forward()
    z = z + 1
    return
end

local function moveNegZ()
    turnTo(1)
    robot.forward()
    z = z - 1
    return
end

-- Moves in y, then z, then x
-- Starting orientation is preserved
local function moveTo(tx, ty, tz)
    local starto = o

    while y < ty do
        movePosY()
    end
    while y > ty do
        moveNegY()
    end

    while z < tz do
        movePosZ()
    end
    while z > tz do
        moveNegZ()
    end

    while x < tx do
        movePosX()
    end
    while x > tx do
        moveNegX()
    end

    turnTo(starto)
end

---------- ---------- ---------- ---------- ---------- ---------- ----------


-- [[ STATES ]] --

-- Forward declaration
local resting

-- Return to charger
-- Wait for full charge
local function charging()
    moveTo(chx, chy+1, chz)
    repeat
        os.sleep(1)
    until getBatteryLevel() >= 0.95
    resting()
end

-- till all designated blocks
-- do not till blocks which are already tilled
local function tilling()
    moveTo(fmx, fmy, fmz)

    for h = 1, fmh do
        local tmpx1, tmpy1, tmpz1 = x, y, z -- start of major row
        for w = 1, fmw do

            -- Till 8x8 square
            for i = 1, 8 do
                local tmpx2, tmpy2, tmpz2 = x, y, z -- start of minor row
                for j = 1, 8 do
                    tillBelow()
                    moveNegX()
                end
                moveTo(tmpx2, tmpy2, z) -- return to start of minor row
                movePosZ()
            end

            moveTo(x - 8, y, z)
        end
        moveTo(tmpx1, tmpy1, z) -- return to start of major row
    end

    computer.pushSignal("SOW")
    resting()
end

-- sow seeds in all designated, tilled, unoccupied blocks
-- return unused seeds to storage
local function sowing()
    moveTo(fmx, fmy, fmz)

    for h = 1, fmh do
        local tmpx1, tmpy1, tmpz1 = x, y, z -- start of major row
        for w = 1, fmw do

            -- Sow 8x8 square
            for i = 1, 8 do
                local tmpx2, tmpy2, tmpz2 = x, y, z -- start of minor row
                for j = 1, 8 do
                    sowBelow()
                    moveNegX()
                end
                moveTo(tmpx2, tmpy2, z) -- return to start of minor row
                movePosZ()
            end

            moveTo(x - 8, y, z)
        end
        moveTo(tmpx1, tmpy1, z) -- return to start of major row
    end

    -- return unused seeds to storage

    harvestTimer = event.Timer(WHEAT_TIMER, computer.pushSignal("HARVEST", computer.uptime()))
    resting()
end

local function harvesting()
    -- Harvest all crops at appropriate intervals
    -- Return harvested crops and seeds to storage
    -- BONUS: havest only mature crops
    computer.pushSignal("TILL")
end

function resting()
    moveTo(0, 0, 0)

    checkBattery()

    local currEvent = nil
    repeat
        currEvent = event.pull(5)
    until currEvent ~= nil

    if currEvent == "HARVEST" then
        harvesting()
    elseif currEvent == "SOW" then
        sowing()
    elseif currEvent == "TILL" then
        tilling()
    elseif currEvent == "CHARGE" then
        charging()
    end
end

---------- ---------- ---------- ---------- ---------- ---------- ----------


-- [[ MAIN ]] --

-- init farm
tilling()