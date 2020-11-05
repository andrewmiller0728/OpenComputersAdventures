
local farmstatus = require("farmstatus")
local thread = require("thread")


-- [[ FarmPlot ]] --

local farmplot = {}


function farmplot.createPlot(plotName, plotCrop)
    local newPlot = {}
    newPlot.name = plotName
    newPlot.cropType = plotCrop
    newPlot.uptime = 0
    newPlot.produced = {}
    newPlot.status = farmstatus["INIT"]
    newPlot.prevStatus = farmstatus["INIT"]

    return newPlot
end


function farmplot.setStatus(plot, status)
    plot.prevStatus = plot.status
    plot.status = status -- I hope these aren't references
    return plot
end


local function trackUptime(plot)
    while true do
        os.sleep(1)
        plot.uptime = plot.uptime + 1
    end
    return true
end

local stopwatch

function farmplot.startTimer(plot)
    local time = {}
    time["H"], time["M"], time["S"] = 0, 0, 0
    stopwatch = thread.create(trackUptime, time)
    return stopwatch
end


function farmplot.killTimer(plot)
    stopwatch:kill()
    return plot
end


return farmplot