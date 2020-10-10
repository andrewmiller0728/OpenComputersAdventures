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


-- [[ SET UP]] --

local component = require("component")
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
local x, y, z, f = 0, 0, 0, 0

---------- ---------- ---------- ---------- ---------- ---------- ----------


-- [[ VARIABLES ]] --
local LOW_BATTERY = 0.15

local WHEAT_TIMER = 30 * 60 -- 30 minutes in seconds
local harvestTimer -- event.Timer(WHEAT_TIMER, 
                               -- computer.pushSignal("HARVEST", computer.uptime()))

---------- ---------- ---------- ---------- ---------- ---------- ----------


-- [[ COMMON TASKS ]] --

local function replaceTool(tool)
    -- Discard current tool
    -- Retrieve new tool from storage
    -- BONUS: if no tools in storage, make one
end

local function getBatteryLevel()
    return computer.energy() / computer.maxEnergy()
end

local function checkBattery()
    local batteryLevel = getBatteryLevel()
    if (batteryLevel <= LOW_BATTERY) then
        computer.pushSignal("CHARGE", batteryLevel)
    end
end

---------- ---------- ---------- ---------- ---------- ---------- ----------


-- [[ MOVEMENT ]] --

local function turnTo(tf)
    if f == tf - 1 then
        robot.turnRight()
        f = (f + 1) % 4
    else
        while f ~= tf do
            robot.turnLeft()
            f = (f - 1) % 4
        end
    end
end

local function moveTo(tx, ty, tz)
    while y < ty do
        robot.up()
        y = y + 1
    end
    while y > ty do
        robot.down()
        y = y - 1
    end

    turnTo(0)
    while z < tz do
        robot.forward()
        z = z + 1
    end
    while z > tz do
        robot.back()
        z = z - 1
    end

    turnTo(3)
    while x < tx do
        robot.forward()
    end
    while x > tx do
        robot.back()
    end
end

---------- ---------- ---------- ---------- ---------- ---------- ----------


-- [[ STATES ]] --

local function resting()
    -- wait for future input
    -- TODO: event.pull()
end

local function charging()
    -- Return to charger
    -- Wait for full charge
end

local function tilling()
    -- till all designated blocks
    -- do not till blocks which are already tilled
end

local function sowing()
    -- sow seeds in all designated, tilled, unoccupied blocks
    -- return unused seeds to storage

    harvestTimer = event.Timer(WHEAT_TIMER, computer.pushSignal("HARVEST", computer.uptime()))
end

local function harvesting()
    -- Harvest all crops at appropriate intervals
    -- Return harvested crops and seeds to storage
    -- BONUS: havest only mature crops
end

---------- ---------- ---------- ---------- ---------- ---------- ----------


-- [[ MAIN ]] --



-- init farm
tilling()
sowing()
resting()