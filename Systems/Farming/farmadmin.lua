
local farmplot = require("farmplot")
local farmstatus = require("farmstatus")

-- [[ FarmAdmin ]] --

local farmadmin = {}

farmadmin.dataset = {}

function farmadmin.createPlot(plotName, plotCrop)
    local newPlot = farmplot.createPlot(plotName, plotCrop)
    table.insert(farmadmin.dataset, newPlot)
    return newPlot
end

function farmadmin.startPlot(plot)
    plot = farmplot.startTimer(plot)
    plot = farmplot.setStatus(plot, farmstatus["SOW"])
    return plot
end

function farmadmin.suspendPlot(plot)
    plot = farmplot.killTimer(plot)
    plot = farmplot.setStatus(plot, farmstatus["SUSPEND"])
    return plot
end

function farmadmin.resumePlot(plot)
    plot = farmplot.startTimer(plot)
    plot = farmplot.setStatus(plot, plot.prevStatus)
    return plot
end

function farmadmin.killPlot(plot)
    plot = farmplot.killTimer(plot)
    plot = farmplot.setStatus(plot, farmstatus["DEAD"])
    return plot
end

function farmadmin.getPlotOutput(plot)

end

return farmadmin