
local farmplot = require("farmplot")

-- [[ FarmAdmin ]] --

local farmadmin = {}

farmadmin.dataset = {}

function farmadmin.createPlot(plotName, plotCrop)
    local newPlot = farmplot.createPlot(plotName, plotCrop)
    table.insert(farmadmin.dataset, newPlot)
    return newPlot
end

function farmadmin.startPlot(plot)

end

function farmadmin.getPlotOutput(plot)

end

return farmadmin