
local farmstatus = require("farmstatus")

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

function farmplot.startTimer(plot)

end

function farmplot.killTimer(plot)

end

return farmplot