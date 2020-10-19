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
--      - https://ocdoc.cil.li/component:inventory_controller

---------- ---------- ---------- ---------- ---------- ---------- ----------


-- [[ VARIABLES ]] --
local LOW_BATTERY = 0.15
local WHEAT_TIMER = 30 * 60 -- 30 minutes in seconds

local harvestTimer

-- Charger Location
local chx, chy, chz
-- Storage Location
local stx, sty, stz
-- Farm Southeast Corner
local fmx, fmy, fmz
-- Farm Square Dimensions
local fmw, fmh

---------- ---------- ---------- ---------- ---------- ---------- ----------


-- [[ SET UP]] --

local component = require("component")
local robotComponent = component.robot
local computer = require("computer")
local robot = require("robot")
local shell = require("shell")
local sides = require("sides")
local event = require("event")
local thread = require("thread")
local inventoryController = component.inventory_controller
local colors = require("colors")

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
-- local farmFile = io.open(filename, "r")
-- for i = 1, io.lines() do
--     io.write(io.read("l"))
-- end
-- io.close(farmFile)

-- Charger Location
chx, chy, chz = 0, 0, 0
-- Storage Location
stx, sty, stz = 0, 0, 0
-- Farm Southwest Corner
fmx, fmy, fmz = 1, 0, 1

-- Save init position and orientation data
local x, y, z, o = 0, 0, 0, 0

---------- ---------- ---------- ---------- ---------- ---------- ----------


-- [[ MOVEMENT ]] --

-- Turns to specified orientation
local function turnTo(to)
    if o == to - 1 or o == 3 then
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
    turnTo(2)
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

-- local function replaceTool(tool)
--     -- Discard current tool
--     -- Retrieve new tool from storage
--     -- BONUS: if no tools in storage, make one
--     return
-- end

-- Tills dirt block below with a hoe
local function tillBelow(lx, ly, lz)
    -- local slot1 = inventoryController.getStackInInternalSlot(1)
    -- if string.match(slot1["id"], ".+_hoe") and slot1["damage"] / slot1["maxDamage"] > 0.95 then
    --     replaceTool("HOE")
    -- end

    local tries = 100
    local flag
    repeat
        flag, _ = robot.useDown()
        tries = tries - 1
    until flag or tries <= 0 or (x == lx - 5 and z == lz + 5)
    return
end

local function tillSquare()
    local lx, ly, lz, lo = x, y, z, o
    
    repeat
        repeat
            tillBelow(lx, ly, lz)
            movePosX()
        until x >= lx + 9
        tillBelow(lx, ly, lz)
        moveTo(lx, ly, z)
        movePosZ()
    until z >= lz + 9
    repeat
        tillBelow(lx, ly, lz)
        movePosX()
    until x <= lx - 9
    tillBelow(lx, ly, lz)
    moveTo(lx, ly, z)
    turnTo(lo)
end

-- if there aren't any seeds in inventory, get seeds
-- select seeds from inventory
-- if the ground below isn't sown, sow a seed
local function sowBelow(lx, ly, lz)
    robotComponent.select(1)
    if robotComponent.count() > 1 then
        local tries = 100
        repeat
            tries = tries - 1
        until tries == 0 or (x == lx - 5 and z == lz + 5) or robot.place(sides.bottom)
        return true
    end
    return false
end

local function sowSquare()
    local lx, ly, lz, lo = x, y, z, o
    
    repeat
        repeat
            sowBelow(lx, ly, lz)
            movePosX()
        until x >= lx + 9
        sowBelow(lx, ly, lz)
        moveTo(lx, ly, z)
        movePosZ()
    until z >= lz + 9

    repeat
        sowBelow(lx, ly, lz)
        movePosX()
    until x >= lx + 9

    sowBelow(lx, ly, lz)
    moveTo(lx, ly, z)
    turnTo(lo)
end

---------- ---------- ---------- ---------- ---------- ---------- ----------


-- [[ STATES ]] --

-- Forward declaration
local resting

-- Return to charger
-- Wait for full charge
local function charging()
    robotComponent.setLightColor(0xff0000)

    moveTo(chx, chy+1, chz)

    repeat
        os.sleep(1)
    until getBatteryLevel() >= 0.95

    return resting()
end

-- till all designated blocks
-- do not till blocks which are already tilled
local function tilling()
    robotComponent.setLightColor(0x999900)

    moveTo(fmx, fmy, fmz)

    tillSquare()

    computer.pushSignal("SOW")

    return resting()
end

-- sow seeds in all designated, tilled, unoccupied blocks
-- return unused seeds to storage
local function sowing()
    robotComponent.setLightColor(0x00ff00)
    moveTo(fmx, fmy, fmz)

    sowSquare()

    -- return unused seeds to storage

    harvestTimer = event.Timer(WHEAT_TIMER, computer.pushSignal("HARVEST", computer.uptime()))
    return resting()
end

-- Harvest all crops at appropriate intervals
-- Return harvested crops and seeds to storage
-- BONUS: havest only mature crops
local function harvesting()
    robotComponent.setLightColor(0x00ffff)

    computer.pushSignal("TILL")

    return resting()
end

function resting()
    robotComponent.setLightColor(0x0000ff)

    moveTo(0, 0, 0)

    checkBattery()

    local currEvent = nil
    repeat
        currEvent = event.pull(5)
    until currEvent ~= nil

    if currEvent == "HARVEST" then
        return harvesting()
    elseif currEvent == "SOW" then
        return sowing()
    elseif currEvent == "TILL" then
        return tilling()
    elseif currEvent == "CHARGE" then
        return charging()
    else
        return resting()
    end
end

---------- ---------- ---------- ---------- ---------- ---------- ----------


-- [[ MAIN ]] --

-- init farm
tilling()