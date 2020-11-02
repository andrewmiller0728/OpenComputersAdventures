
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

    return newPlot
end

return farmplot