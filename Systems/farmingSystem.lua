local component = require("component")
local computer = require("computer")
local sides = require("sides")
local thread = require("thread")
local event = require("event")

local w, h = component.gpu.getResolution()
component.gpu.setDepth(component.gpu.maxDepth())


-- [[ METHODS ]] --

local function trackTime(time)
    while true do
        os.sleep(1)
        time["S"] = time["S"] + 1
        if time["S"] == 60 then
            time["M"] = time["M"] + 1
            time["S"] = 0
        end
        if time["M"] == 60 then
            time["H"] = time["H"] + 1
            time["M"] = 0
            time["S"] = 0 -- not pos needed
        end
    end
    return true
end

local function signalPusher()
    computer.pushSignal("TIMER")
    return true
end

local function openFlood()
    component.redstone.setOutput(sides.left, 0)
    return true
end

local function closeFlood()
    component.redstone.setOutput(sides.left, 15)
    return true
end

local function drawBorder(thickness)
    component.gpu.setBackground(0x3C3C3C) --Grey
    component.gpu.setForeground(0x006D00) --Dark Green
    component.gpu.fill(1, 1, w, h, " ")
    component.gpu.fill(1, 1, w, thickness, "#")
    component.gpu.fill(1, h - (thickness - 1), w, thickness, "#")
end

local function drawStatus(boxX, boxY, boxW, boxH, text)
    local textW = string.len(text)
    local textX, textY = (boxX + (boxW / 2)) - (textW / 2), boxY + (boxH / 2)

    component.gpu.setForeground(0xFF9200)  --Orange
    component.gpu.fill(boxX, boxY, boxW, boxH, "-")

    component.gpu.setForeground(0xFFFFFF) --White
    component.gpu.set(textX, textY, text)
end


-- [[ MAIN ]] --

-- Outline:
-- Multiple farm plots run at once
-- Farm plot statuses: {Sowing, Growing, Harvesting, Suspended, Dead}
-- Sowing:
--      <Crop> seeds are planted in each available block of farmland by robot
--      Robot returns to charger
--      Set status to Growing
-- Growing:
--      Timer is set for <duration>
--      When timer goes off, set status to Harvesting
-- Harvesting:
--      Flood plot with water from dispensers/pistons
--      Wait for collection
--      Close dispensers/pistons
--      Set status to Sowing
-- Suspended:
--      Plot is paused and current status is saved
--      Dispensers/pistons are closed if open
--      A suspended plot can be resumed back to the status it was suspended in
-- Dead:
--      Plot is killed regardless of status
--      Dispensers/pistons are closed if open
--      Plot data is removed from memory
--      A dead plot cannot be resumed