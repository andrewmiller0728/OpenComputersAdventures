
local component = require("component")
local gpu = component.gpu

local w, h = gpu.getResolution()

gpu.setDepth(gpu.maxDepth())
gpu.setBackground(0x3C3C3C)
gpu.setForeground(0x000000)
gpu.fill(1, 1, w, h, " ")


local function getMooreSpace(cellTable, cellX, cellY)
    local mooreSpace = {cellTable[cellX][cellY - 1],     -- North
                        cellTable[cellX + 1][cellY - 1], -- Northeast
                        cellTable[cellX + 1][cellY],     -- East
                        cellTable[cellX + 1][cellY - 1], -- Southeast
                        cellTable[cellX][cellY - 1],     -- South
                        cellTable[cellX - 1][cellY - 1], -- Southwest
                        cellTable[cellX - 1][cellY],     -- West
                        cellTable[cellX - 1][cellY + 1], -- Northwest
                       }
    return mooreSpace
end

local function getNeighborCount(mooreSpace)
    local neighborsCount = 0
    for n = 1, 8 do
        if mooreSpace[n] == 1 then
            neighborsCount = neighborsCount + 1
        end
    end
    return neighborsCount
end

local function getNextStatus(cell, n)
    if (cell == 1 and (n == 2 or n == 3)) or (cell == 0 and n == 3) then
        return 1
    else
        return 0
    end
end

local function getNextCells(cells)
    local nextCells = {}
    for x = 1, w do
        local column = {}
        for y = 1, h do
            table.insert(column, 0)
        end
        table.insert(nextCells, column)
    end
    for x = 2, w - 1 do
        for y = 2, h - 1 do
            local nCount = getNeighborCount(getMooreSpace(cells, x, y))
            nextCells[x][y] = getNextStatus(cells[x][y], nCount)
        end
    end
    return nextCells
end

local function drawCells(cells)
    for x = 1, w do
        for y = 1, h do
            if cells[x][y] == 1 then
                gpu.set(x, y, "&")
            elseif cells[x][y] == 0 then
                gpu.set(x, y, " ")
            else
                return false
            end
        end
    end
    return true
end


local cells = {}
local iterations = 1000
local delay = 0.1

-- Fill base cells
for x = 1, w do
    local column = {}
    for y = 1, h do
        if y > h / 2 - 10 and y < h / 2 + 10 then
            table.insert(column, 1)
        else
            table.insert(column, 0)
        end
    end
    table.insert(cells, column)
end

-- Loop simulation
for n = 1, iterations do
    drawCells(cells)
    cells = getNextCells(cells)
    os.sleep(delay)
end