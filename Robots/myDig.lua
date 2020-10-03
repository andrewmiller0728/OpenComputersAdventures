local component = require("component")
local robot = require("robot")
local shell = require("shell")

--[[ Set Up ]]--

-- Program must be run on a robot
if not component.isAvailable("robot") then
    io.stderr:write("can only run on robots")
    return
end

-- Take in command line arguments
local args, ops = shell.parse(...)
if #args < 1 then
    io.write("Usage: dig [-s] <size_x> <size_y>\n")
    io.write(" -s: shutdown when done")
    return
end

-- Validate command line arguments
local sizeX, sizeY = tonumber(args[1]), tonumber(args[2])
if not sizeX or not sizeY then
    io.stderr:write("Invalid size parameters")
    return
end

--[[ MOVEMENT ]]--

-- (x, y, z) coordinates and r rotation {0 <= x <= 3}, xN
local x, y, z, r = 0, 0, 0, 0

-- Moves the robot forward 1 block
local function moveForward()
    -- Try to move forward 1 block
    -- if blocked, check if block can be mined
    -- log that moved forward 1 block
    return
end