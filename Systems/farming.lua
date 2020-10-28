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

local function drawStatus(text)
    local boxW, boxH = 48, 8
    local boxX, boxY = (w / 2) - (boxW / 2), (h / 2) - (boxH / 2)

    local textW = string.len(text)
    local textX, textY = (w / 2) - (textW / 2), h / 2

    component.gpu.setForeground(0xFF9200)  --Orange
    component.gpu.fill(boxX, boxY, boxW, boxH, "=")

    component.gpu.setForeground(0xFFFFFF) --White
    component.gpu.set(textX, textY, text)
end


-- [[ MAIN ]] --

component.gpu.fill(1, 1, w, h, " ")
drawBorder(3)
component.gpu.set(1, 1, string.format("Max color depth: %d", component.gpu.maxDepth()))

drawStatus("Preparing...")
closeFlood()
os.sleep(10)

local growTime = 30 * 60
local timer = event.timer(growTime, signalPusher)

local time = {}
time["H"], time["M"], time["S"] = 0, 0, 0
local stopwatch = thread.create(trackTime, time)

while event.pull(1, "TIMER") == nil do
    drawStatus(string.format("Grow Timer: %d:%d:%d", time["H"], time["M"], time["S"]))
end

drawStatus("Flooding")
openFlood()
os.sleep(30)
closeFlood()

component.gpu.setBackground(0x000000) --Black
component.gpu.fill(1, 1, w, h, " ")

stopwatch:kill()

