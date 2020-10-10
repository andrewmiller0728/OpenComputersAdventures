-- [[ PLANT FARMING ROBOT ]]--
-- Goals:
--      - Sowing seeds in tilled soil
--      - Maintaining grounds
--      - Harvest at appropriate intervals
--      - Organize storage of resouces and products
--      - Have a personal UX
--      - Keep track of production rate

 ---------- ---------- ---------- ---------- ---------- ---------- ----------


-- [[ SET UP]] --

local component = require("component")
local computer = require("computer")
local robot = require("robot")
local shell = require("shell")
local sides = require("sides")

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

-- Parse farm file and build database

---------- ---------- ---------- ---------- ---------- ---------- ----------


-- [[ VARIABLES ]] --

---------- ---------- ---------- ---------- ---------- ---------- ----------


-- [[ FORWARD DECLARATION ]] --

local resting
local charging
local tilling
local sowing
local harvesting

local replaceTool

---------- ---------- ---------- ---------- ---------- ---------- ----------


-- [[ MAIN ]] --

local function main()
    local run = true
    -- Central loop, think like arduino code
    while (run) do
        -- Based on if...else switch between states
        
    end
end

---------- ---------- ---------- ---------- ---------- ---------- ----------


-- [[ STATES ]] --

function resting()
    -- wait for future input
end

function charging()
    -- Return to charger
    -- Wait for full charge
end

function tilling()
    -- till all designated blocks
    -- do not till blocks which are already tilled
end

function sowing()
    -- sow seeds in all designated, tilled, unoccupied blocks
    -- return unused seeds to storage
end

function harvesting()
    -- Harvest all crops at appropriate intervals
    -- Return harvested crops and seeds to storage
    -- BONUS: havest only mature crops
end

---------- ---------- ---------- ---------- ---------- ---------- ----------


-- [[ COMMON TASKS ]] --

function replaceTool(tool)
    -- Discard current tool
    -- Retrieve new tool from storage
    -- BONUS: if no tools in storage, make one
end

---------- ---------- ---------- ---------- ---------- ---------- ----------